#!/usr/bin/env bash

NVIM_PRESET="${NVIM_PRESET:-lazyvim-stylish}"

apply_nvim_config() {
    resolve_configs || return 1
    local preset="${1:-$NVIM_PRESET}" src=""
    case "$preset" in
        lazyvim-stylish)
            [[ -d "$CONFIGS_DIR/nvim-presets/lazyvim-stylish" ]] && src="$CONFIGS_DIR/nvim-presets/lazyvim-stylish"
            [[ -z "$src" && -d "$CONFIGS_DIR/nvim" ]] && src="$CONFIGS_DIR/nvim"
            ;;
        super-easy-casual) src="$CONFIGS_DIR/nvim-presets/super-easy-casual" ;;
        *) src="$CONFIGS_DIR/nvim-presets/$preset" ;;
    esac
    [[ -d "$src" ]] || { err "Nvim preset not found: $preset"; return 1; }
    local dst="$HOME/.config/nvim"; stash_dir "$dst"; mkdir -p "$dst"
    cp -a "$src/." "$dst/"; normalize_paths "$dst"
    ok "$(t nvim_preset_applied "$preset")"
}

action_install_neovim() {
    ensure_sudo || return 1
    case "$PLATFORM" in
        arch) pkg_install neovim wl-clipboard ;;
        debian) pkg_install neovim wl-clipboard || pkg_install neovim ;;
    esac
    apply_nvim_config "${1:-$NVIM_PRESET}" || true
    ok "$(t nvim_ready)"
}

action_neovim_menu() {
    require_module lib/menu.sh
    menu_select "Neovim" \
        "1|$(t nvim_light)" \
        "2|$(t nvim_complex)" \
        "0|$(t menu_back)" || return 0
    case "$MENU_CHOICE" in
        1) action_install_neovim super-easy-casual ;;
        2) action_install_neovim lazyvim-stylish ;;
    esac
}
