#!/usr/bin/env bash

action_update_system() {
    ensure_sudo || return 1
    info "$(t system_update)"
    pkg_update
    ok "$(t system_updated)"
}

action_install_aur_helper() {
    [[ "$PLATFORM" == "arch" ]] || { info "$(t aur_arch_only)"; return 0; }
    ensure_sudo || return 1
    if has yay || has paru; then ok "$(t aur_exists "$(aur_helper)")"; return 0; fi
    local choice="${1:-yay}"
    sudo pacman -S --needed --noconfirm git base-devel || return 1
    ensure_work_dir
    local repo="https://aur.archlinux.org/${choice}.git"
    git clone "$repo" "$WORK_DIR/$choice" || return 1
    (cd "$WORK_DIR/$choice" && makepkg -si --noconfirm) || return 1
    ok "$(t pkg_installed "$choice")"
}
