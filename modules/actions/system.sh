#!/usr/bin/env bash

action_update_system() {
    ensure_sudo || return 1
    info "Обновление системы..."
    pkg_update
    ok "Система обновлена."
}

action_install_aur_helper() {
    [[ "$PLATFORM" == "arch" ]] || { info "AUR helper нужен только на Arch."; return 0; }
    ensure_sudo || return 1
    if has yay || has paru; then ok "AUR helper уже установлен: $(aur_helper)"; return 0; fi
    local choice="${1:-yay}"
    sudo pacman -S --needed --noconfirm git base-devel || return 1
    ensure_work_dir
    local repo="https://aur.archlinux.org/${choice}.git"
    git clone "$repo" "$WORK_DIR/$choice" || return 1
    (cd "$WORK_DIR/$choice" && makepkg -si --noconfirm) || return 1
    ok "$choice установлен."
}
