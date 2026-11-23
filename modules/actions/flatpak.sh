#!/usr/bin/env bash

action_install_flatpak() {
    ensure_sudo || return 1
    pkg_install flatpak || return 1
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
    ok "Flatpak/Flathub готовы."
}
