#!/usr/bin/env bash

# Full interactive install: sectioned choices + checkboxes.

action_full_interactive() {
    require_module lib/menu.sh
    require_module actions/preflight.sh
    require_module actions/system.sh
    require_module actions/software.sh
    require_module actions/fish.sh
    require_module actions/neovim.sh
    require_module actions/fetches.sh
    require_module actions/dotfiles.sh
    require_module actions/flatpak.sh
    require_module actions/network.sh

    action_preflight install || return 1
    info "$(t interactive_start)"

    # Profile
    menu_select "$(t dotfiles_profile)" \
        "1|stylish-dots (fish + nvim + fetches)" \
        "2|$(t profile_end4)" \
        "3|MangoWC" \
        "4|$(t profile_none)" || return 1
    local profile="$MENU_CHOICE"

    # Neovim preset: bootstrap уже мог выбрать его заранее.
    local nvim_choice
    case "${NVIM_PRESET:-}" in
        lazyvim-stylish) nvim_choice=1 ;;
        super-easy-casual) nvim_choice=2 ;;
        *)
            menu_select "Neovim preset" \
                "1|$(t nvim_recommended)" \
                "2|$(t nvim_old)" \
                "3|$(t nvim_none)" || return 1
            nvim_choice="$MENU_CHOICE"
            ;;
    esac

    # Fastfetch preset
    menu_select "Fastfetch preset" \
        "1|$(t ff_mine)" \
        "2|default" \
        "3|micro" \
        "4|stylish" \
        "5|universal" \
        "6|$(t ff_none)" || return 1
    local ff_choice="$MENU_CHOICE"

    # Components
    local -a items=(
        "update|$(t comp_update)|off"
        "basic|$(t comp_basic)|on"
        "aur|$(t comp_aur)|off"
        "fish|$(t comp_fish)|on"
        "rust-fetches|Rust 3D fetches (keyfetch/treefetch/...)|on"
        "flatpak|Flatpak + Flathub|off"
        "warp|Cloudflare WARP (Arch)|off"
        "firewall|Firewall (ufw)|off"
        "home-readme|$(t comp_home_readme)|off"
    )
    select_packages "$(t components)" "${items[@]}" || return 1

    local profile_name nvim_name ff_name
    case "$profile" in
        1) profile_name="stylish-dots (fish + nvim + fetches)";;
        2) profile_name="end-4 / illogical-impulse";;
        3) profile_name="MangoWC";;
        4) profile_name="$(t no_apply)";;
        *) profile_name="$profile";;
    esac
    case "$nvim_choice" in
        1) nvim_name="lazyvim-stylish";;
        2) nvim_name="super-easy-casual";;
        3) nvim_name="$(t no_install)";;
        *) nvim_name="$nvim_choice";;
    esac
    case "$ff_choice" in
        1) ff_name="mine";; 2) ff_name="default";; 3) ff_name="micro";;
        4) ff_name="stylish";; 5) ff_name="universal";; 6) ff_name="$(t no_set)";;
        *) ff_name="$ff_choice";;
    esac

    echo
    echo -e "${BOLD}${CYAN}================== OVERVIEW ==================${NC}"
    echo -e "${BOLD}$(t overview_profile):${NC} $profile_name"
    echo -e "${BOLD}Neovim preset:${NC}    $nvim_name"
    echo -e "${BOLD}Fastfetch preset:${NC} $ff_name"
    echo -e "${BOLD}$(t overview_components):${NC}"
    local comp
    for comp in update basic aur fish rust-fetches flatpak warp firewall home-readme; do
        local mark="[-]"; local desc="$comp"
        case "$comp" in
            update) desc="$(t comp_update)";;
            basic) desc="$(t comp_basic)";;
            aur) desc="$(t comp_aur)";;
            fish) desc="$(t comp_fish)";;
            rust-fetches) desc="Rust 3D fetches (keyfetch/treefetch/...)";;
            flatpak) desc="Flatpak + Flathub";;
            warp) desc="Cloudflare WARP (Arch)";;
            firewall) desc="Firewall (ufw)";;
            home-readme) desc="$(t comp_home_readme)";;
        esac
        for p in "${SELECTED_PACKAGES[@]}"; do [[ "$p" == "$comp" ]] && mark="[x]"; done
        echo "  $mark $desc"
    done
    echo -e "${BOLD}$(t overview_will)${NC}"
    for p in "${SELECTED_PACKAGES[@]}"; do echo "  - $p"; done
    [[ "$nvim_choice" != "3" ]] && echo "  - neovim preset: $nvim_name"
    [[ "$ff_choice" != "6" ]] && echo "  - fastfetch preset: $ff_name"
    [[ "$profile" != "4" ]] && echo "  - dotfiles profile: $profile_name"
    echo -e "${BOLD}${CYAN}===============================================${NC}"
    echo
    is_interactive && ! confirm "$(t confirm_install)" && return 1

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

    ok "$(t interactive_done)"
}

action_full_auto() {
    require_module actions/preflight.sh
    require_module actions/system.sh
    require_module actions/software.sh
    require_module actions/fish.sh
    require_module actions/neovim.sh
    require_module actions/fetches.sh
    action_preflight install || return 1
    action_update_system || true
    action_install_basic || true
    action_install_fish || true
    action_install_neovim "${NVIM_PRESET:-lazyvim-stylish}" || true
    action_install_fastfetch_preset mine || true
    action_build_rust_fetches || true
    ok "$(t auto_done)"
}

action_install_dotfiles_only() {
    require_module lib/menu.sh
    require_module actions/preflight.sh
    require_module actions/dotfiles.sh
    action_preflight dotfiles || return 1

    menu_select "$(t dotfiles_only_profile)" \
        "1|stylish-dots (fish + nvim config only)" \
        "2|end-4 / illogical-impulse config" \
        "3|MangoWC config" \
        "0|$(t menu_back)" || return 0
    local profile="$MENU_CHOICE"
    [[ "$profile" == "0" ]] && return 0

    menu_select "Neovim config preset" \
        "1|lazyvim-stylish" "2|super-easy-casual" "3|$(t no_change)" || return 1
    local nvim_choice="$MENU_CHOICE"
    menu_select "Fastfetch config preset" \
        "1|mine" "2|default" "3|micro" "4|stylish" "5|universal" "6|$(t no_change)" || return 1
    local ff_choice="$MENU_CHOICE"

    echo
    echo -e "${BOLD}${CYAN}== DOTFILES-ONLY OVERVIEW ==${NC}"
    echo "  profile=$profile nvim=$nvim_choice fastfetch=$ff_choice"
    echo "$(t dotfiles_only_notice)"
    echo "$(t dotfiles_only_notice2)"
    is_interactive && ! confirm "$(t confirm_apply)" && return 1

    case "$nvim_choice" in
        1|2)
            require_module actions/neovim.sh
            local preset="lazyvim-stylish"; [[ "$nvim_choice" == "2" ]] && preset="super-easy-casual"
            apply_nvim_config "$preset" || warn "nvim config failed"
            ;;
    esac
    case "$ff_choice" in
        1|2|3|4|5)
            require_module actions/fetches.sh
            local p; case "$ff_choice" in 1) p=mine;; 2) p=default;; 3) p=micro;; 4) p=stylish;; 5) p=universal;; esac
            action_copy_fastfetch_preset "$p" || warn "fastfetch config failed"
            ;;
    esac
    case "$profile" in
        1) action_apply_stylish_configs_only "$nvim_choice" || warn "profile failed" ;;
        2) action_apply_end4 || warn "end4 failed" ;;
        3) action_apply_mango || warn "mango failed" ;;
    esac
    ok "$(t dotfiles_only_done)"
}
