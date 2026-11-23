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
        grep -Fq $'\t'"$target"$'\t'"$bk" "$BACKUP_REGISTRY" 2>/dev/null || backup_register "$target" "$bk"
    done < <(find "$dir" -mindepth 1 -maxdepth 3 \( -type f -o -type d \) -print0 2>/dev/null)
}

backup_import_legacy() {
    mkdir -p "$(dirname "$BACKUP_REGISTRY")"
    local d
    for d in "$HOME"/.config-backup-end4-*; do backup_import_legacy_dir "$d" end4; done
    for d in "$HOME"/.config-backup-mango-*; do backup_import_legacy_dir "$d" mango; done
}

action_backup_list() {
    backup_import_legacy
    if [[ ! -f "$BACKUP_REGISTRY" ]]; then info "Бэкапов не найдено."; return 0; fi
    echo -e "${BOLD}${CYAN}== Бэкапы stylish-dots (последние 50) ==${NC}"
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
    [[ -n "$profile" ]] || { err "Укажи профиль: end4|mango|stylish"; return 1; }
    backup_import_legacy
    [[ -f "$BACKUP_REGISTRY" ]] || { err "Реестр бэкапов пуст: $BACKUP_REGISTRY"; return 1; }
    local -a targets=()
    case "$profile" in
        end4) targets=("$HOME/.config/hypr/custom" "$HOME/.config/hypr/hyprland/keybinds.lua" "$HOME/.config/illogical-impulse/config.json" "$HOME/.config/environment.d/10-cursor.conf" "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini" "$HOME/.icons/default/index.theme") ;;
        mango) targets=("$HOME/.config/mango" "$HOME/.config/waybar" "$HOME/.config/foot" "$HOME/.config/fuzzel" "$HOME/.config/mako" "$HOME/.config/matugen" "$HOME/.local/bin/mango-settings") ;;
        stylish) targets=("$HOME/.config/fish" "$HOME/.config/nvim" "$HOME/.config/fastfetch" "$HOME/README.md") ;;
        *) err "Неизвестный профиль: $profile"; return 1 ;;
    esac
    local t
    for t in "${targets[@]}"; do
        local bk
        bk=$(awk -F'	' -v t="$t" '$2==t{b=$3} END{print b}' "$BACKUP_REGISTRY")
        if [[ -n "$bk" && (-e "$bk" || -L "$bk") ]]; then
            action_restore_backup "$t" || warn "restore failed: $t"
        else
            info "Нет бэкапа для $t, пропуск"
        fi
    done
    ok "Rollback профиля $profile завершён (где были бэкапы)."
}

action_restore_backup() {
    local target="${1:-}"
    backup_import_legacy
    [[ -f "$BACKUP_REGISTRY" ]] || { err "Реестр бэкапов пуст: $BACKUP_REGISTRY"; return 1; }

    local bk=""
    if [[ -z "$target" ]]; then
        action_backup_list
        local n; read -rp "Номер для восстановления (q отмена): " n
        [[ "$n" =~ ^[Qq]$ || -z "$n" ]] && return 0
        [[ "$n" =~ ^[0-9]+$ ]] || { err "Неверный номер"; return 1; }
        target=$(sed -n "${n}p" "$BACKUP_REGISTRY" | awk -F'\t' '{print $2}')
        bk=$(sed -n "${n}p" "$BACKUP_REGISTRY" | awk -F'\t' '{print $3}')
        [[ -n "$target" && -n "$bk" ]] || { err "Запись не найдена"; return 1; }
    else
        bk=$(awk -F'\t' -v t="$target" '$2==t{b=$3} END{print b}' "$BACKUP_REGISTRY")
    fi

    [[ -n "$bk" && (-e "$bk" || -L "$bk") ]] || { err "Бэкап не существует: $bk"; return 1; }
    if [[ -e "$target" || -L "$target" ]]; then
        local cur="${target}.before-restore.$(date +%Y%m%d_%H%M%S)"
        mv "$target" "$cur"
        backup_register "$target" "$cur"
        info "Текущее сохранено: $cur"
    fi
    mkdir -p "$(dirname "$target")"
    cp -a "$bk" "$target"
    ok "Восстановлено: $target <- $bk (оригинальный бэкап сохранён)"
}
