#!/usr/bin/env bash

# Minimal software catalog; modules can be extended independently of GUI.
BASIC_PKGS_ARCH=(git base-devel curl wget unzip zip tar htop fastfetch)
BASIC_PKGS_DEBIAN=(git build-essential curl wget unzip zip tar htop fastfetch)

action_install_basic() {
    ensure_sudo || return 1
    if [[ "$PLATFORM" == "arch" ]]; then pkg_install "${BASIC_PKGS_ARCH[@]}";
    else pkg_install "${BASIC_PKGS_DEBIAN[@]}"; fi
    ok "$(t basic_installed)"
}

action_software_menu() {
    require_module lib/menu.sh
    require_module actions/fetches.sh
    require_module actions/flatpak.sh
    while true; do
        menu_select "$(t software_install)" \
            "1|$(t software_basic)" \
            "2|Flatpak + Flathub" \
            "3|$(t software_fetches)" \
            "4|Fish" \
            "5|Neovim" \
            "0|$(t menu_back)" || return 0
        case "$MENU_CHOICE" in
            1) action_install_basic; pause ;;
            2) action_install_flatpak; pause ;;
            3) action_fetches_menu; pause ;;
            4) require_module actions/fish.sh; action_install_fish; pause ;;
            5) require_module actions/neovim.sh; action_install_neovim; pause ;;
            0) return 0 ;;
        esac
    done
}
