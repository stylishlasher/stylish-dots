#!/usr/bin/env bash
# Module loader: downloads module file if missing, then sources it.

MODULES_DIR="${MODULES_DIR:-$SCRIPT_DIR/modules}"
MODULES_RAW_BASE="${MODULES_RAW_BASE:-https://raw.githubusercontent.com/${REPO_SLUG:-stylishlasher/stylish-dots}/${REPO_BRANCH:-main}/modules}"

require_module() {
    local rel="$1" # e.g. actions/fish.sh
    local path="$MODULES_DIR/$rel"
    if [[ -f "$path" ]]; then
        # shellcheck disable=SC1090
        source "$path"
        return 0
    fi

    mkdir -p "$(dirname "$path")"
    local url="$MODULES_RAW_BASE/$rel"
    info "Докачиваю модуль: $rel"
    curl -fsSL "$url" -o "$path" || { err "Не удалось скачать модуль: $url"; return 1; }
    # shellcheck disable=SC1090
    source "$path"
}

run_action() {
    local action="$1"; shift || true
    case "$action" in
        update_system) require_module actions/system.sh; action_update_system "$@" ;;
        install_aur_helper) require_module actions/system.sh; action_install_aur_helper "$@" ;;
        install_fish) require_module actions/fish.sh; action_install_fish "$@" ;;
        install_neovim) require_module actions/neovim.sh; action_install_neovim "$@" ;;
        install_mpv) require_module actions/media.sh; action_install_mpv "$@" ;;
        install_gsr) require_module actions/media.sh; action_install_gsr "$@" ;;
        install_archives) require_module actions/media.sh; action_install_archives "$@" ;;
        install_flatpak) require_module actions/flatpak.sh; action_install_flatpak "$@" ;;
        install_warp) require_module actions/network.sh; action_install_warp "$@" ;;
        configure_firewall) require_module actions/network.sh; action_configure_firewall "$@" ;;
        install_fastfetch_preset) require_module actions/fetches.sh; action_install_fastfetch_preset "$@" ;;
        build_rust_fetches) require_module actions/fetches.sh; action_build_rust_fetches "$@" ;;
        fetches_menu) require_module actions/fetches.sh; action_fetches_menu "$@" ;;
        apply_mango) require_module actions/dotfiles.sh; action_apply_mango "$@" ;;
        apply_end4) require_module actions/dotfiles.sh; action_apply_end4 "$@" ;;
        apply_stylish) require_module actions/dotfiles.sh; action_apply_stylish "$@" ;;
        install_dotfiles_profile) require_module actions/dotfiles.sh; action_install_dotfiles_profile "$@" ;;
        software_menu) require_module actions/software.sh; action_software_menu "$@" ;;
        full_interactive) require_module actions/interactive.sh; action_full_interactive "$@" ;;
        full_auto) require_module actions/interactive.sh; action_full_auto "$@" ;;
        apply_configs) require_module actions/dotfiles.sh; action_apply_configs "$@" ;;
        quick_audit) require_module actions/audit.sh; action_quick_audit "$@" ;;
        *) err "Неизвестное действие: $action"; return 1 ;;
    esac
}
