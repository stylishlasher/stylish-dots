#!/usr/bin/env bash

# Полная установка: 4 шага (профиль -> ПО -> конфиги -> применение).

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
    require_module actions/extras.sh
    require_module actions/console.sh

    action_preflight install || return 1
    info "$(t interactive_start)"

    # Шаг 1: профиль dotfiles
    menu_select "$(t wizard_profile)" \
        "1|$(t profile_caelestia)" \
        "2|$(t profile_stylish)" \
        "3|$(t profile_end4)" \
        "4|$(t profile_mango)" \
        "5|$(t profile_serpantinum)" \
        "8|$(t profile_none)" || return 1
    local profile="$MENU_CHOICE"
    local profile_name="" theme_name="" profile_id=""
    case "$profile" in
        1) profile_id=caelestia; profile_name="$(t profile_caelestia)"; theme_name=caelestia ;;
        2) profile_id=stylish-dots; profile_name="$(t profile_stylish)"; theme_name=stylish ;;
        3) profile_id=end-4; profile_name="$(t profile_end4)"; theme_name=end4 ;;
        4) profile_id=mango; profile_name="$(t profile_mango)" ;;
        5) profile_id=serpantinum; profile_name="$(t profile_serpantinum)"; theme_name=serpantinum ;;
        8) profile_name="$(t profile_none)" ;;
    esac
    if [[ "$profile" == "8" ]]; then
        menu_select "$(t sddm_theme_select)" \
            "1|$(t profile_caelestia)" \
            "2|$(t profile_end4)" \
            "3|$(t profile_stylish)" \
            "4|$(t profile_serpantinum)" \
            "0|$(t profile_none)" || return 1
        case "$MENU_CHOICE" in
            1) theme_name=caelestia ;;
            2) theme_name=end4 ;;
            3) theme_name=stylish ;;
            4) theme_name=serpantinum ;;
        esac
    fi

    # Шаг 2: ПО и системные удобства
    local -A labels=(
        [update]="$(t comp_update)"
        [basic]="$(t comp_basic)"
        [browser]="$(t comp_browser)"
        [discord]="$(t comp_discord)"
        [telegram]="$(t comp_telegram)"
        [steam]="$(t comp_steam)"
        [aur]="$(t comp_aur)"
        [sddm]="$(t comp_sddm)"
        [sddm-theme]="$(t comp_sddm_theme) ${theme_name:-$(t profile_none)}"
        [fish]="$(t comp_fish)"
        [rust-fetches]="$(t comp_rust_fetches)"
        [flatpak]="$(t comp_flatpak)"
        [warp]="$(t comp_warp)"
        [firewall]="$(t comp_firewall)"
        [cursors]="$(t comp_cursors)"
        [monitors]="$(t comp_monitors)"
        [home-readme]="$(t comp_home_readme)"
        [console-toys]="$(t comp_console)"
    )
    local -a comp_order=(update basic browser discord telegram steam aur sddm)
    [[ -n "$theme_name" ]] && comp_order+=(sddm-theme)
    comp_order+=(fish rust-fetches flatpak warp firewall cursors monitors home-readme console-toys)
    local -a items=()
    local comp
    for comp in "${comp_order[@]}"; do
        local def=off
        [[ "$comp" == "basic" || "$comp" == "fish" || "$comp" == "rust-fetches" ]] && def=on
        items+=("$comp|${labels[$comp]}|$def")
    done
    select_packages "$(t wizard_software)" "${items[@]}" || return 1

    # Шаг 3: конфиги и пресеты
    menu_select "$(t wizard_configs) — Neovim" \
        "1|$(t nvim_recommended)" \
        "2|$(t nvim_old)" \
        "3|$(t nvim_none)" || return 1
    local nvim_choice="$MENU_CHOICE"
    menu_select "$(t fastfetch_preset)" \
        "1|$(t ff_mine)" \
        "2|$(t preset_default)" \
        "3|$(t preset_micro)" \
        "4|$(t preset_stylish)" \
        "5|$(t preset_universal)" \
        "6|$(t ff_none)" || return 1
    local ff_choice="$MENU_CHOICE"
    menu_select "$(t cursor_theme)" \
        "1|$(t cursor_classic)" \
        "2|$(t cursor_ice)" \
        "3|$(t cursor_none)" || return 1
    local cursor_choice="$MENU_CHOICE"

    local nvim_preset="" ff_preset="" cursor_theme=""
    case "$nvim_choice" in
        1) nvim_preset=lazyvim-stylish ;;
        2) nvim_preset=super-easy-casual ;;
    esac
    case "$ff_choice" in
        1) ff_preset=mine ;; 2) ff_preset=default ;; 3) ff_preset=micro ;;
        4) ff_preset=stylish ;; 5) ff_preset=universal ;;
    esac
    case "$cursor_choice" in
        1) cursor_theme=Bibata-Modern-Classic ;;
        2) cursor_theme=Bibata-Modern-Ice ;;
    esac

    # Шаг 4: сводка и подтверждение
    echo
    echo -e "${BOLD}${CYAN}================== OVERVIEW ==================${NC}"
    echo -e "${BOLD}$(t overview_profile):${NC} $profile_name"
    echo -e "${BOLD}Neovim:${NC}    ${nvim_preset:-$(t no_install)}"
    echo -e "${BOLD}Fastfetch:${NC} ${ff_preset:-$(t no_set)}"
    echo -e "${BOLD}$(t cursor_theme):${NC} ${cursor_theme:-$(t cursor_none)}"
    echo -e "${BOLD}$(t overview_components):${NC}"
    for comp in "${comp_order[@]}"; do
        local mark="[-]"
        for p in "${SELECTED_PACKAGES[@]}"; do [[ "$p" == "$comp" ]] && mark="[x]"; done
        echo "  $mark ${labels[$comp]}"
    done
    echo -e "${BOLD}$(t overview_will)${NC}"
    for p in "${SELECTED_PACKAGES[@]}"; do echo "  - ${labels[$p]:-$p}"; done
    [[ -n "$nvim_preset" ]] && echo "  - Neovim: $nvim_preset"
    [[ -n "$ff_preset" ]] && echo "  - Fastfetch: $ff_preset"
    [[ -n "$cursor_theme" ]] && echo "  - $(t cursor_theme): $cursor_theme"
    [[ "$profile" != "5" ]] && echo "  - $(t overview_profile): $profile_name"
    echo -e "${BOLD}${CYAN}===============================================${NC}"
    echo
    is_interactive && ! confirm "$(t confirm_install)" && return 1

    local p
    for p in "${SELECTED_PACKAGES[@]}"; do
        case "$p" in
            update) action_update_system || warn "update failed" ;;
            basic) action_install_basic || warn "basic failed" ;;
            browser) pkg_install firefox || warn "firefox failed" ;;
            discord) pkg_install discord || warn "discord failed" ;;
            telegram) pkg_install telegram-desktop || warn "telegram failed" ;;
            steam) pkg_install steam || warn "steam failed" ;;
            aur) action_install_aur_helper yay || warn "aur helper failed" ;;
            sddm) action_install_sddm || warn "sddm failed" ;;
            sddm-theme) action_install_sddm_theme "$theme_name" || warn "sddm theme failed" ;;
            fish) action_install_fish || warn "fish failed" ;;
            rust-fetches) action_build_rust_fetches || warn "rust fetches failed" ;;
            flatpak) action_install_flatpak || warn "flatpak failed" ;;
            warp) action_install_warp || warn "warp failed" ;;
            firewall) action_configure_firewall || warn "firewall failed" ;;
            cursors) action_install_bibata && apply_bibata_theme "$cursor_theme" || warn "cursors failed" ;;
            monitors) action_setup_monitors || warn "monitors failed" ;;
            home-readme) require_module actions/extras.sh; action_create_home_readme || warn "home readme failed" ;;
            console-toys) action_install_console_toys || warn "console toys failed" ;;
        esac
    done

    [[ -n "$nvim_preset" ]] && { action_install_neovim "$nvim_preset" || warn "nvim failed"; }
    [[ -n "$ff_preset" ]] && { action_install_fastfetch_preset "$ff_preset" || warn "fastfetch failed"; }

    case "$profile_id" in
        "") ;;
        *) action_install_dotfiles_profile "$profile_id" --yes || warn "profile apply failed" ;;
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
    action_install_neovim lazyvim-stylish || true
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
        "1|$(t profile_stylish)" \
        "2|$(t profile_end4)" \
        "3|$(t profile_caelestia)" \
        "4|$(t profile_mango)" \
        "5|DarkShadowShell (GUI install)" \
        "6|MacShell (GUI install)" \
        "7|$(t profile_serpantinum)" \
        "0|$(t menu_back)" || return 0
    local profile="$MENU_CHOICE" profile_id=""
    [[ "$profile" == "0" ]] && return 0
    case "$profile" in
        1) profile_id=stylish-dots ;;
        2) profile_id=end-4 ;;
        3) profile_id=caelestia ;;
        4) profile_id=mango ;;
        5) profile_id=darkshadowshell ;;
        6) profile_id=macshell ;;
        7) profile_id=serpantinum ;;
    esac

    menu_select "Neovim config preset" \
        "1|lazyvim-stylish" "2|super-easy-casual" "3|$(t no_change)" || return 1
    local nvim_choice="$MENU_CHOICE"
    menu_select "Fastfetch config preset" \
        "1|mine" "2|default" "3|micro" "4|stylish" "5|universal" "6|$(t no_change)" || return 1
    local ff_choice="$MENU_CHOICE"

    echo
    echo -e "${BOLD}${CYAN}== DOTFILES-ONLY OVERVIEW ==${NC}"
    echo "  profile=$profile_id nvim=$nvim_choice fastfetch=$ff_choice"
    echo "$(t dotfiles_only_notice)"
    echo "$(t dotfiles_backup_note)"
    is_interactive && ! confirm "$(t confirm_apply)" && return 1

    case "$nvim_choice" in
        1|2)
            local preset="lazyvim-stylish"; [[ "$nvim_choice" == "2" ]] && preset="super-easy-casual"
            NVIM_PRESET="$preset"
            ;;
        *) NVIM_PRESET="" ;;
    esac
    action_install_dotfiles_profile "$profile_id" --yes || { warn "profile failed"; return 1; }
    case "$ff_choice" in
        1|2|3|4|5)
            require_module actions/fetches.sh
            local p; case "$ff_choice" in 1) p=mine;; 2) p=default;; 3) p=micro;; 4) p=stylish;; 5) p=universal;; esac
            action_copy_fastfetch_preset "$p" || warn "fastfetch config failed"
            ;;
    esac
    if [[ "$profile_id" != "stylish-dots" && ( "$nvim_choice" == "1" || "$nvim_choice" == "2" ) ]]; then
        require_module actions/neovim.sh
        apply_nvim_config "$NVIM_PRESET" || warn "nvim config failed"
    fi
    ok "$(t dotfiles_only_done)"
}
