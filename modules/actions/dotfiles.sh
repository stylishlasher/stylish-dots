#!/usr/bin/env bash

DOTFILES_PROFILE="${DOTFILES_PROFILE:-end-4}"
NVIM_PRESET="${NVIM_PRESET:-lazyvim-stylish}"

apply_mango_config() {
    resolve_configs || return 1
    if [[ -f "$CONFIGS_DIR/mango/install.sh" ]]; then
        bash "$CONFIGS_DIR/mango/install.sh"
        return $?
    fi
    err "MangoWC config not found ($CONFIGS_DIR/mango/install.sh)"; return 1
}

apply_end4_config() {
    resolve_configs || return 1
    if [[ -f "$CONFIGS_DIR/end4/install.sh" ]]; then
        bash "$CONFIGS_DIR/end4/install.sh"
        return $?
    fi
    err "end-4 config not found ($CONFIGS_DIR/end4/install.sh)"; return 1
}

apply_stylish_configs_only() {
    local nvim_choice="${1:-3}"
    require_module actions/fish.sh
    has fish && { apply_fish_config || warn "fish config not applied"; } || warn "fish не найден, конфиг пропущен"
    if [[ "$nvim_choice" != "3" ]]; then
        require_module actions/neovim.sh
        local preset="lazyvim-stylish"; [[ "$nvim_choice" == "2" ]] && preset="super-easy-casual"
        apply_nvim_config "$preset" || warn "nvim config not applied"
    fi
}

action_apply_stylish_configs_only() { apply_stylish_configs_only "$@"; }

apply_stylish_configs() {
    require_module actions/fish.sh
    require_module actions/neovim.sh
    require_module actions/fetches.sh
    apply_fish_config || warn "fish config not applied"
    action_build_rust_fetches || warn "Rust fetches not built"
    install_fish_plugins || true
    apply_nvim_config "${1:-$NVIM_PRESET}" || warn "nvim config not applied"
}

action_apply_mango() { apply_mango_config; }
action_apply_end4() { apply_end4_config; }
action_apply_stylish() { apply_stylish_configs "${1:-$NVIM_PRESET}"; }

action_apply_configs() {
    require_module lib/menu.sh
    menu_select "Применить конфиги" \
        "1|stylish-dots (fish+nvim+rust fetches)" \
        "2|end-4 / illogical-impulse" \
        "3|MangoWC" \
        "4|Fastfetch preset" \
        "0|Назад" || return 0
    case "$MENU_CHOICE" in
        1) action_apply_stylish ;;
        2) action_apply_end4 ;;
        3) action_apply_mango ;;
        4) require_module actions/fetches.sh; action_fetches_menu ;;
        0) return 0 ;;
    esac
}

action_install_dotfiles_profile() {
    local profile="${1:-$DOTFILES_PROFILE}"
    case "$profile" in
        stylish-dots) action_apply_stylish ;;
        end-4) action_apply_end4 ;;
        serpantinum)
            warn "Serpantinum installer is external; run its official installer, then apply themes from config/themes.";
            info "Example: curl -fsSL https://install.serpantinum.dev | bash"
            ;;
        *) err "Unknown profile: $profile"; return 1 ;;
    esac
}
