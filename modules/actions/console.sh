#!/usr/bin/env bash

# Консольные приколы: локальные копии скриптов из config/bin и fish-функций.
CONSOLE_TOYS=(csorting hackerlarp)

action_install_console_toy() {
    local name="${1:-csorting}"
    case "$name" in
        csorting|hackerlarp) ;;
        *) err "$(t console_toy_unknown "$name")"; return 1 ;;
    esac
    resolve_configs || return 1
    local src="$CONFIGS_DIR/bin/$name" dst="$HOME/.local/bin/$name"
    [[ -f "$src" ]] || { err "$(t console_toy_missing "$name")"; return 1; }
    mkdir -p "$HOME/.local/bin" || return 1
    install -m 0755 "$src" "$dst" || return 1

    local fsrc="$CONFIGS_DIR/fish/functions/$name.fish" fdst="$HOME/.config/fish/functions/$name.fish"
    if has fish && [[ -f "$fsrc" ]]; then
        mkdir -p "$(dirname "$fdst")" || return 1
        install -m 0644 "$fsrc" "$fdst" || return 1
    fi
    ok "$(t console_toy_installed "$name")"
}

action_install_console_toys() {
    local name
    for name in "${CONSOLE_TOYS[@]}"; do
        action_install_console_toy "$name" || return 1
    done
}

action_console_menu() {
    require_module lib/menu.sh
    while true; do
        menu_select "$(t console_toys)" \
            "1|$(t console_csorting)" \
            "2|$(t console_hackerlarp)" \
            "3|$(t console_toys) — csorting + hackerlarp" \
            "0|$(t menu_back)" || return 0
        case "$MENU_CHOICE" in
            1) action_install_console_toy csorting; pause ;;
            2) action_install_console_toy hackerlarp; pause ;;
            3) action_install_console_toys; pause ;;
            0) return 0 ;;
        esac
    done
}
