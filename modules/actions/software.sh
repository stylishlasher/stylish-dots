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
    require_module actions/extras.sh
    require_module actions/console.sh
    while true; do
        menu_select "$(t software_install)" \
            "1|$(t software_basic)" \
            "2|$(t comp_flatpak)" \
            "3|$(t software_fetches)" \
            "4|Fish" \
            "5|Neovim" \
            "6|$(t comp_sddm)" \
            "7|$(t profile_caelestia)" \
            "8|$(t profile_darkshadowshell)" \
            "9|$(t profile_macshell)" \
            "10|$(t comp_cursors)" \
            "11|$(t comp_monitors)" \
            "12|$(t sddm_themes_install)" \
            "13|$(t sddm_image_change)" \
            "14|$(t console_toys)" \
            "0|$(t menu_back)" || return 0
        case "$MENU_CHOICE" in
            1) action_install_basic; pause ;;
            2) action_install_flatpak; pause ;;
            3) action_fetches_menu; pause ;;
            4) require_module actions/fish.sh; action_install_fish; pause ;;
            5) require_module actions/neovim.sh; action_neovim_menu; pause ;;
            6) action_install_sddm; pause ;;
            7) require_module actions/dotfiles.sh; action_install_dotfiles_profile caelestia; pause ;;
            8) require_module actions/dotfiles.sh; action_install_dotfiles_profile darkshadowshell; pause ;;
            9) require_module actions/dotfiles.sh; action_install_dotfiles_profile macshell; pause ;;
            10) action_cursors_menu ;;
            11) action_setup_monitors; pause ;;
            12) action_install_sddm_themes; pause ;;
            13) action_set_sddm_image; pause ;;
            14) action_console_menu; pause ;;
            0) return 0 ;;
        esac
    done
}
