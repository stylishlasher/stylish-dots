#!/usr/bin/env bash

action_preflight() {
    local mode="${1:-install}" # install|dotfiles|uninstall
    local -a missing=()
    local -a cmds=(bash curl tar git find cp mv mkdir date sed grep awk)
    [[ "$mode" == "install" ]] && cmds+=(sudo)
    local c
    for c in "${cmds[@]}"; do has "$c" || missing+=("$c"); done

    if [[ "$PLATFORM" == "arch" ]]; then
        has pacman || missing+=("pacman")
    elif [[ "$PLATFORM" == "debian" ]]; then
        has apt-get || missing+=("apt-get")
    fi

    if (( ${#missing[@]} )); then
        err "Отсутствуют команды/зависимости: ${missing[*]}"
        return 1
    fi

    if [[ "$mode" == "install" ]]; then
        ensure_sudo || return 1
    fi

    if [[ "$PLATFORM" == "arch" && "${IS_CACHYOS:-0}" == "1" ]]; then
        info "Обнаружен CachyOS: используется Arch-совместимый путь (pacman/AUR)."
    fi
    ok "Preflight OK ($mode, platform=$PLATFORM${IS_CACHYOS:+, cachyos=$IS_CACHYOS})"
}
