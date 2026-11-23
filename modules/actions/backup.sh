#!/usr/bin/env bash

BACKUP_REGISTRY="${BACKUP_REGISTRY:-${XDG_STATE_HOME:-$HOME/.local/state}/stylish-dots/backups.tsv}"

action_backup_list() {
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

action_restore_backup() {
    local target="${1:-}"
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
