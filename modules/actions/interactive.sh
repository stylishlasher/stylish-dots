#!/usr/bin/env bash

# Full interactive install: sectioned choices + checkboxes.

action_full_interactive() {
    require_module lib/menu.sh
    require_module actions/system.sh
    require_module actions/software.sh
    require_module actions/fish.sh
    require_module actions/neovim.sh
    require_module actions/fetches.sh
    require_module actions/dotfiles.sh
    require_module actions/flatpak.sh
    require_module actions/network.sh

    info "Полная интерактивная установка: выбери профиль, пресеты и компоненты."

    # Profile
    menu_select "Профиль dotfiles" \
        "1|stylish-dots (fish + nvim + fetches)" \
        "2|end-4 / illogical-impulse (поверх dots-hyprland)" \
        "3|MangoWC" \
        "4|Не применять профиль dotfiles" || return 1
    local profile="$MENU_CHOICE"

    # Neovim preset
    menu_select "Neovim preset" \
        "1|lazyvim-stylish (рекомендуется)" \
        "2|super-easy-casual (старый лёгкий)" \
        "3|Не устанавливать Neovim" || return 1
    local nvim_choice="$MENU_CHOICE"

    # Fastfetch preset
    menu_select "Fastfetch preset" \
        "1|mine (как у меня)" \
        "2|default" \
        "3|micro" \
        "4|stylish" \
        "5|universal" \
        "6|Не ставить fastfetch preset" || return 1
    local ff_choice="$MENU_CHOICE"

    # Components
    local -a items=(
        "update|Обновить систему|off"
        "basic|Базовый набор пакетов|on"
        "aur|AUR helper yay (только Arch)|off"
        "fish|Fish + конфиг|on"
        "rust-fetches|Rust 3D fetches (keyfetch/treefetch/...)|on"
        "flatpak|Flatpak + Flathub|off"
        "warp|Cloudflare WARP (Arch)|off"
        "firewall|Firewall (ufw)|off"
        "home-readme|Создать ~/README.md (обои + Firefox расширения)|on"
    )
    select_packages "Компоненты (галочки)" "${items[@]}" || return 1

    echo
    info "План:"
    echo "  profile=$profile nvim=$nvim_choice fastfetch=$ff_choice"
    echo "  components: ${SELECTED_PACKAGES[*]:-(none)}"
    is_interactive && ! confirm "Начать установку?" && return 1

    local p
    for p in "${SELECTED_PACKAGES[@]}"; do
        case "$p" in
            update) action_update_system || warn "update failed" ;;
            basic) action_install_basic || warn "basic failed" ;;
            aur) action_install_aur_helper yay || warn "aur helper failed" ;;
            fish) action_install_fish || warn "fish failed" ;;
            rust-fetches) action_build_rust_fetches || warn "rust fetches failed" ;;
            flatpak) action_install_flatpak || warn "flatpak failed" ;;
            warp) action_install_warp || warn "warp failed" ;;
            firewall) action_configure_firewall || warn "firewall failed" ;;
            home-readme) require_module actions/extras.sh; action_create_home_readme || warn "home readme failed" ;;
        esac
    done

    case "$nvim_choice" in
        1) action_install_neovim lazyvim-stylish || warn "nvim failed" ;;
        2) action_install_neovim super-easy-casual || warn "nvim failed" ;;
        3) ;;
    esac

    case "$ff_choice" in
        1) action_install_fastfetch_preset mine || warn "fastfetch failed" ;;
        2) action_install_fastfetch_preset default || warn "fastfetch failed" ;;
        3) action_install_fastfetch_preset micro || warn "fastfetch failed" ;;
        4) action_install_fastfetch_preset stylish || warn "fastfetch failed" ;;
        5) action_install_fastfetch_preset universal || warn "fastfetch failed" ;;
        6) ;;
    esac

    case "$profile" in
        1) action_apply_stylish "${nvim_choice}" || warn "profile apply failed" ;;
        2) action_apply_end4 || warn "end4 apply failed" ;;
        3) action_apply_mango || warn "mango apply failed" ;;
        4) ;;
    esac

    ok "Полная интерактивная установка завершена."
}

action_full_auto() {
    require_module actions/system.sh
    require_module actions/software.sh
    require_module actions/fish.sh
    require_module actions/neovim.sh
    require_module actions/fetches.sh
    action_update_system || true
    action_install_basic || true
    action_install_fish || true
    action_install_neovim lazyvim-stylish || true
    action_install_fastfetch_preset mine || true
    action_build_rust_fetches || true
    ok "Авто-установка завершена."
}
