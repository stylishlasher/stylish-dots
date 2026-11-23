#!/usr/bin/env bash

BACKUP_REGISTRY="${XDG_STATE_HOME:-$HOME/.local/state}/stylish-dots/backups.tsv"

backup_register() {
    local src="$1" bk="$2"
    mkdir -p "$(dirname "$BACKUP_REGISTRY")"
    printf '%s\t%s\t%s\n' "$(date '+%F %T')" "$src" "$bk" >> "$BACKUP_REGISTRY"
}

stash_dir() {
    local dst="$1"
    [[ -e "$dst" || -L "$dst" ]] || return 0
    local bk="${dst}.bak.$(date +%Y%m%d_%H%M%S)"
    mv "$dst" "$bk"
    backup_register "$dst" "$bk"
    info "Backup: $bk"
}

action_backup_list() {
    if [[ ! -f "$BACKUP_REGISTRY" ]]; then info "Бэкапов не найдено."; return 0; fi
    echo -e "${BOLD}${CYAN}== Бэкапы stylish-dots ==${NC}"
    nl -ba "$BACKUP_REGISTRY" | tail -n 50
}

action_restore_backup() {
    local target="${1:-}"
    if [[ ! -f "$BACKUP_REGISTRY" ]]; then err "Реестр бэкапов пуст: $BACKUP_REGISTRY"; return 1; fi

    if [[ -z "$target" ]]; then
        action_backup_list
        local n; read -rp "Номер для восстановления (q отмена): " n
        [[ "$n" =~ ^[Qq]$ || -z "$n" ]] && return 0
        [[ "$n" =~ ^[0-9]+$ ]] || { err "Неверный номер"; return 1; }
        target=$(sed -n "${n}p" "$BACKUP_REGISTRY" | awk -F'\t' '{print $2}')
        local bk; bk=$(sed -n "${n}p" "$BACKUP_REGISTRY" | awk -F'\t' '{print $3}')
        [[ -n "$target" && -n "$bk" ]] || { err "Запись не найдена"; return 1; }
        [[ -e "$bk" || -L "$bk" ]] || { err "Бэкап не существует: $bk"; return 1; }
        if [[ -e "$target" || -L "$target" ]]; then
            local cur="${target}.before-restore.$(date +%Y%m%d_%H%M%S)"
            mv "$target" "$cur"
            info "Текущее сохранено: $cur"
        fi
        mkdir -p "$(dirname "$target")"
        cp -a "$bk" "$target"
        ok "Восстановлено: $target <- $bk"
        return 0
    fi

    # target path given: restore latest backup for it
    local bk
    bk=$(awk -F'\t' -v t="$target" '$2==t{b=$3} END{print b}' "$BACKUP_REGISTRY")
    [[ -n "$bk" && (-e "$bk" || -L "$bk") ]] || { err "Бэкап для $target не найден"; return 1; }
    if [[ -e "$target" || -L "$target" ]]; then
        mv "$target" "${target}.before-restore.$(date +%Y%m%d_%H%M%S)"
    fi
    mkdir -p "$(dirname "$target")"
    cp -a "$bk" "$target"
    ok "Восстановлено: $target <- $bk"
}
