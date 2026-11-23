#!/usr/bin/env bash
# Platform abstraction for stylish-dots modules.

detect_platform() {
    if [[ -n "${STYLISH_PLATFORM:-}" ]]; then
        PLATFORM="$STYLISH_PLATFORM"
    elif command -v pacman >/dev/null 2>&1; then
        PLATFORM="arch"
    elif command -v apt-get >/dev/null 2>&1 || command -v dpkg >/dev/null 2>&1; then
        PLATFORM="debian"
    else
        PLATFORM="unknown"
    fi
    IS_CACHYOS="0"
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        [[ "${ID:-}" == "cachyos" || "${ID_LIKE:-}" == *cachyos* || "${NAME:-}" == *CachyOS* ]] && IS_CACHYOS="1"
    fi
    export PLATFORM IS_CACHYOS
}

pkg_update() {
    case "$PLATFORM" in
        arch) sudo pacman -Syu --noconfirm ;;
        debian) sudo apt-get update && sudo apt-get upgrade -y ;;
        *) err "Unsupported platform: $PLATFORM"; return 1 ;;
    esac
}

INSTALLED_PKGS_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/stylish-dots/installed-packages.txt"
track_installed_pkgs() {
    mkdir -p "$(dirname "$INSTALLED_PKGS_STATE")"
    local p
    for p in "$@"; do
        grep -qxF "$p" "$INSTALLED_PKGS_STATE" 2>/dev/null || echo "$p" >> "$INSTALLED_PKGS_STATE"
    done
}

pkg_install() {
    local -a pkgs=("$@")
    (( ${#pkgs[@]} )) || return 0
    case "$PLATFORM" in
        arch)
            if has yay; then yay -S --needed --noconfirm "${pkgs[@]}"
            elif has paru; then paru -S --needed --noconfirm "${pkgs[@]}"
            else sudo pacman -S --needed --noconfirm "${pkgs[@]}"
            fi
            ;;
        debian)
            sudo apt-get install -y "${pkgs[@]}"
            ;;
        *) err "Unsupported platform: $PLATFORM"; return 1 ;;
    esac || return 1
    track_installed_pkgs "${pkgs[@]}"
}

pac_install() { pkg_install "$@"; }

aur_helper() {
    if has yay; then echo yay; elif has paru; then echo paru; else echo ""; fi
}
