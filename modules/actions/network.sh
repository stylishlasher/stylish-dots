#!/usr/bin/env bash

action_install_warp() {
    [[ "$PLATFORM" == "arch" ]] || { warn "$(t warp_arch_only)"; return 1; }
    ensure_sudo || return 1
    pkg_install cloudflare-warp-bin || return 1
    sudo systemctl enable --now warp-svc.service || true
    warp-cli --accept-tos registration new >/dev/null 2>&1 || true
    warp-cli --accept-tos connect >/dev/null 2>&1 || true
    ok "$(t warp_installed)"
}

action_configure_firewall() {
    ensure_sudo || return 1
    if has ufw; then sudo ufw enable; ok "ufw enabled"; return 0; fi
    if [[ "$PLATFORM" == "arch" ]]; then pkg_install ufw && sudo systemctl enable --now ufw && sudo ufw enable; fi
    if [[ "$PLATFORM" == "debian" ]]; then pkg_install ufw && sudo ufw enable; fi
}
