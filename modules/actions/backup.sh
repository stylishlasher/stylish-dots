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
            backup_register "$target" "$bk" || warn "Не удалось зарегистрировать legacy backup: $bk"
        fi
    done < <(find "$dir" -mindepth 1 -maxdepth 3 \( -type f -o -type d \) -print0 2>/dev/null)
}

backup_import_legacy() {
    mkdir -p "$(dirname "$BACKUP_REGISTRY")" || { err "Не удалось создать каталог реестра: $(dirname "$BACKUP_REGISTRY")"; return 1; }
    touch "$BACKUP_REGISTRY" || { err "Не удалось создать реестр бэкапов: $BACKUP_REGISTRY"; return 1; }
    local d
    for d in "$HOME"/.config-backup-end4-*; do backup_import_legacy_dir "$d" end4; done
    for d in "$HOME"/.config-backup-mango-*; do backup_import_legacy_dir "$d" mango; done
}

action_backup_list() {
    backup_import_legacy || return 1
    if [[ ! -s "$BACKUP_REGISTRY" ]]; then info "Бэкапов не найдено."; return 0; fi
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
    backup_import_legacy || return 1
    local -a targets=()
    case "$profile" in
        end4) targets=("$HOME/.config/hypr/custom" "$HOME/.config/hypr/hyprland/keybinds.lua" "$HOME/.config/illogical-impulse/config.json" "$HOME/.config/environment.d/10-cursor.conf" "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini" "$HOME/.icons/default/index.theme") ;;
        mango) targets=("$HOME/.config/mango" "$HOME/.config/waybar" "$HOME/.config/foot" "$HOME/.config/fuzzel" "$HOME/.config/mako" "$HOME/.config/matugen" "$HOME/.local/bin/mango-settings") ;;
        stylish) targets=("$HOME/.config/fish" "$HOME/.config/nvim" "$HOME/.config/fastfetch" "$HOME/README.md") ;;
        *) err "Неизвестный профиль: $profile"; return 1 ;;
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
            echo "  [remove]  $t (действующего бэкапа не найдено, путь будет убран в backup)"
            plan+=("remove|$t")
        else
            echo "  [skip]    $t (нет бэкапа и текущего пути)"
        fi
    done
    is_interactive && ! confirm "Выполнить rollback профиля $profile?" && return 1

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
        err "Rollback профиля $profile завершён с ошибками: ok=$okc fail=$failed"
        return 1
    fi
    ok "Rollback профиля $profile завершён: $okc действий"
}

action_restore_backup() {
    local target="${1:-}"
    backup_import_legacy || return 1
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
        [[ -e "$bk" || -L "$bk" ]] || { err "Бэкап не существует: $bk"; return 1; }
    else
        while IFS=$'\t' read -r _ src bkp; do
            [[ "$src" == "$target" && -n "$bkp" && (-e "$bkp" || -L "$bkp") ]] && bk="$bkp"
        done < "$BACKUP_REGISTRY"
        [[ -n "$bk" ]] || { err "Действующий бэкап для $target не найден"; return 1; }
    fi

    local cur=""
    if [[ -e "$target" || -L "$target" ]]; then
        cur="${target}.before-restore.$(date +%Y%m%d_%H%M%S)"
        mv "$target" "$cur" || { err "Не удалось сохранить текущее состояние: $target"; return 1; }
        if backup_register "$target" "$cur"; then
            info "Текущее сохранено: $cur"
        else
            err "Текущее состояние перемещено в $cur, но не записано в реестр; пробую вернуть его обратно"
            if mv "$cur" "$target" 2>/dev/null; then
                err "Возвращено прежнее состояние: $target"
            else
                err "Не удалось вернуть $cur -> $target; восстанови вручную"
            fi
            return 1
        fi
    fi

    mkdir -p "$(dirname "$target")" || {
        err "Не удалось создать каталог: $(dirname "$target")"
        [[ -n "$cur" && (-e "$cur" || -L "$cur") && ! -e "$target" && ! -L "$target" ]] && mv "$cur" "$target" 2>/dev/null && warn "Возвращено прежнее состояние: $target"
        return 1
    }

    local tmp="${target}.restore-tmp.$$"
    rm -rf "$tmp"
    if cp -a "$bk" "$tmp"; then
        rm -rf "$target"
        if mv "$tmp" "$target"; then
            ok "Восстановлено: $target <- $bk (оригинальный бэкап сохранён)"
            return 0
        fi
    fi

    err "Не удалось восстановить $target из $bk"
    rm -rf "$tmp" 2>/dev/null || true
    if [[ -n "$cur" && (-e "$cur" || -L "$cur") ]]; then
        rm -rf "$target" 2>/dev/null || true
        if mv "$cur" "$target" 2>/dev/null; then
            warn "Возвращено прежнее состояние: $target"
        else
            err "Не удалось автоматически вернуть прежнее состояние; оно сохранено в: $cur"
        fi
    fi
    return 1
}
