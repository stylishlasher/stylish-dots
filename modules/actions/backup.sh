#!/usr/bin/env bash

BACKUP_REGISTRY="${BACKUP_REGISTRY:-${XDG_STATE_HOME:-$HOME/.local/state}/stylish-dots/backups.tsv}"

backup_import_legacy_dir() {
    local dir="$1" prefix="$2"
    [[ -d "$dir" ]] || return 0
    local bk rel target
    while IFS= read -r -d '' bk; do
        rel="${bk#$dir/}"
        case "$prefix:$rel" in
            end4:hypr/custom) target="$HOME/.config/hypr/custom" ;;
            end4:hypr/hyprland/keybinds.lua) target="$HOME/.config/hypr/hyprland/keybinds.lua" ;;
            end4:illogical-impulse/config.json) target="$HOME/.config/illogical-impulse/config.json" ;;
            end4:environment.d/10-cursor.conf) target="$HOME/.config/environment.d/10-cursor.conf" ;;
            end4:gtk-3.0/settings.ini) target="$HOME/.config/gtk-3.0/settings.ini" ;;
            end4:gtk-4.0/settings.ini) target="$HOME/.config/gtk-4.0/settings.ini" ;;
            end4:icons-default/index.theme) target="$HOME/.icons/default/index.theme" ;;
            mango:mango|mango:waybar|mango:foot|mango:fuzzel|mango:mako|mango:matugen) target="$HOME/.config/$rel" ;;
            mango:mango-settings) target="$HOME/.local/bin/mango-settings" ;;
            *) continue ;;
        esac
        if ! grep -Fq $'\t'"$target"$'\t'"$bk" "$BACKUP_REGISTRY" 2>/dev/null; then
            backup_register "$target" "$bk" || warn "$(t legacy_register_failed "$bk")"
        fi
    done < <(find "$dir" -mindepth 1 -maxdepth 3 \( -type f -o -type d \) -print0 2>/dev/null)
}

backup_import_legacy() {
    mkdir -p "$(dirname "$BACKUP_REGISTRY")" || { err "$(t registry_dir_failed "$(dirname "$BACKUP_REGISTRY")")"; return 1; }
    touch "$BACKUP_REGISTRY" || { err "$(t registry_create_failed "$BACKUP_REGISTRY")"; return 1; }
    backup_prune_registry || warn "$(t registry_prune_failed "$BACKUP_REGISTRY")"
    local d
    for d in "$HOME"/.config-backup-end4-*; do backup_import_legacy_dir "$d" end4; done
    for d in "$HOME"/.config-backup-mango-*; do backup_import_legacy_dir "$d" mango; done
}

action_backup_list() {
    backup_import_legacy || return 1
    if [[ ! -s "$BACKUP_REGISTRY" ]]; then info "$(t no_backups)"; return 0; fi
    echo -e "${BOLD}${CYAN}$(t backup_list_header)${NC}"
    local total start i line
    total=$(wc -l < "$BACKUP_REGISTRY")
    start=$(( total > 50 ? total - 49 : 1 ))
    for ((i=start; i<=total; i++)); do
        line=$(sed -n "${i}p" "$BACKUP_REGISTRY")
        printf "%4d  %s\n" "$i" "$line"
    done
}

action_restore_profile() {
    local profile="${1:-}"
    [[ -n "$profile" ]] || { err "$(t profile_required)"; return 1; }
    backup_import_legacy || return 1
    local -a targets=()
    case "$profile" in
        end4|end-4) targets=("$HOME/.config/hypr/custom" "$HOME/.config/hypr/hyprland/keybinds.lua" "$HOME/.config/illogical-impulse/config.json" "$HOME/.config/environment.d/10-cursor.conf" "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini" "$HOME/.icons/default/index.theme") ;;
        mango) targets=("$HOME/.config/mango" "$HOME/.config/waybar" "$HOME/.config/foot" "$HOME/.config/fuzzel" "$HOME/.config/mako" "$HOME/.config/matugen" "$HOME/.local/bin/mango-settings") ;;
        stylish|stylish-dots) targets=("$HOME/.config/fish" "$HOME/.config/nvim" "$HOME/.config/fastfetch" "$HOME/README.md") ;;
        caelestia) targets=("$HOME/.config/caelestia" "$HOME/.config/quickshell/caelestia" "$HOME/.local/state/caelestia") ;;
        darkshadowshell) targets=("$HOME/.config/quickshell/rice-desktop" "$HOME/.config/quickshell/rice-settings" "$HOME/.config/quickshell/rice-welcome" "$HOME/.config/quickshell/hyprquickpaper" "$HOME/.config/quickshell/rice-apps" "$HOME/.config/hypr/user.lua" "$HOME/.local/share/darkshadows-shell") ;;
        macshell) targets=("$HOME/.config/quickshell/MacShell" "$HOME/.config/quickshell/MacLock" "$HOME/.config/hypr-macshell" "$HOME/.config/macbar" "$HOME/.config/macdock" "$HOME/.config/macwidgets" "$HOME/.config/macshell") ;;
        serpantinum) targets=("$HOME/.local/state/serpantinum" "$HOME/.config/quickshell/serpantinum") ;;
        *) err "$(t unknown_profile "$profile")"; return 1 ;;
    esac

    echo -e "${BOLD}${CYAN}== Rollback: $profile ==${NC}"
    local t bk; local -a plan=()
    for t in "${targets[@]}"; do
        bk=""
        while IFS=$'\t' read -r _ src bkp; do
            [[ "$src" == "$t" && -n "$bkp" && (-e "$bkp" || -L "$bkp") ]] && bk="$bkp"
        done < "$BACKUP_REGISTRY"
        if [[ -n "$bk" ]]; then
            echo "  [restore] $t <- $bk"
            plan+=("restore|$t")
        elif [[ -e "$t" || -L "$t" ]]; then
            echo "  [remove]  $t $(t remove_no_backup)"
            plan+=("remove|$t")
        else
            echo "  [skip]    $t $(t skip_no_path)"
        fi
    done
    is_interactive && ! confirm "$(t confirm_rollback "$profile")" && return 1

    local failed=0 okc=0 item
    for item in "${plan[@]}"; do
        local op="${item%%|*}"; local path="${item#*|}"
        if [[ "$op" == "restore" ]]; then
            if action_restore_backup "$path"; then okc=$((okc+1)); else warn "restore failed: $path"; failed=$((failed+1)); fi
        else
            if stash_dir "$path"; then okc=$((okc+1)); else warn "remove failed: $path"; failed=$((failed+1)); fi
        fi
    done

    if (( failed )); then
        err "$(t rollback_failed "$profile" "$okc" "$failed")"
        return 1
    fi
    ok "$(t rollback_done "$profile" "$okc")"
}

action_restore_backup() {
    local target="${1:-}"
    backup_import_legacy || return 1
    [[ -f "$BACKUP_REGISTRY" ]] || { err "$(t registry_empty "$BACKUP_REGISTRY")"; return 1; }

    local bk=""
    if [[ -z "$target" ]]; then
        action_backup_list
        local n; read -rp "$(t restore_number_prompt): " n || return 1
        [[ "$n" =~ ^[Qq]$ || -z "$n" ]] && return 0
        [[ "$n" =~ ^[0-9]+$ ]] || { err "$(t invalid_number)"; return 1; }
        target=$(sed -n "${n}p" "$BACKUP_REGISTRY" | awk -F'\t' '{print $2}')
        bk=$(sed -n "${n}p" "$BACKUP_REGISTRY" | awk -F'\t' '{print $3}')
        [[ -n "$target" && -n "$bk" ]] || { err "$(t entry_not_found)"; return 1; }
        [[ -e "$bk" || -L "$bk" ]] || { err "$(t backup_missing "$bk")"; return 1; }
    else
        while IFS=$'\t' read -r _ src bkp; do
            [[ "$src" == "$target" && -n "$bkp" && (-e "$bkp" || -L "$bkp") ]] && bk="$bkp"
        done < "$BACKUP_REGISTRY"
        [[ -n "$bk" ]] || { err "$(t no_valid_backup "$target")"; return 1; }
    fi

    local cur="" n=0
    if [[ -e "$target" || -L "$target" ]]; then
        cur="${target}.before-restore.$(backup_stamp)"
        while [[ -e "$cur" || -L "$cur" ]]; do
            n=$((n+1))
            cur="${target}.before-restore.$(backup_stamp).$n"
        done
        mv "$target" "$cur" || { err "$(t save_current_failed "$target")"; return 1; }
        if backup_register "$target" "$cur"; then
            info "$(t current_saved "$cur")"
        else
            err "$(t current_moved_unregistered "$cur")"
            if mv "$cur" "$target" 2>/dev/null; then
                err "$(t previous_restored "$target")"
            else
                err "$(t restore_manually "$cur" "$target")"
            fi
            return 1
        fi
    fi

    mkdir -p "$(dirname "$target")" || {
        err "$(t mkdir_failed "$(dirname "$target")")"
        [[ -n "$cur" && (-e "$cur" || -L "$cur") && ! -e "$target" && ! -L "$target" ]] && mv "$cur" "$target" 2>/dev/null && warn "$(t previous_restored "$target")"
        return 1
    }

    local tmpdir tmp
    tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/stylish-restore.XXXXXX") || {
        err "$(t tmpdir_failed)"
        [[ -n "$cur" && (-e "$cur" || -L "$cur") ]] && mv "$cur" "$target" 2>/dev/null && warn "$(t previous_restored "$target")"
        return 1
    }
    tmp="$tmpdir/payload"
    if cp -a "$bk" "$tmp"; then
        rm -rf "$target"
        if mv "$tmp" "$target"; then
            rm -rf "$tmpdir" 2>/dev/null || true
            ok "$(t restore_done "$target" "$bk")"
            return 0
        fi
    fi

    err "$(t restore_copy_failed "$target" "$bk")"
    rm -rf "$tmpdir" 2>/dev/null || true
    if [[ -n "$cur" && (-e "$cur" || -L "$cur") ]]; then
        rm -rf "$target" 2>/dev/null || true
        if mv "$cur" "$target" 2>/dev/null; then
            warn "$(t previous_restored "$target")"
        else
            err "$(t auto_rollback_failed "$cur")"
        fi
    fi
    return 1
}
