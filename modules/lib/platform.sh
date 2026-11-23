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

pkg_is_installed() {
    local p="$1"
    case "$PLATFORM" in
        arch) pacman -Q "$p" >/dev/null 2>&1 ;;
        debian) dpkg-query -W -f='${db:Status-Status}' "$p" 2>/dev/null | grep -qx 'installed' ;;
        *) return 1 ;;
    esac
}

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

    local -a pre_missing=()
    local p
    for p in "${pkgs[@]}"; do
        pkg_is_installed "$p" || pre_missing+=("$p")
    done

    local rc=0
    case "$PLATFORM" in
        arch)
            if has yay; then yay -S --needed --noconfirm "${pkgs[@]}"
            elif has paru; then paru -S --needed --noconfirm "${pkgs[@]}"
            else sudo pacman -S --needed --noconfirm "${pkgs[@]}"
            fi || rc=$?
            ;;
        debian)
            sudo apt-get install -y "${pkgs[@]}" || rc=$?
            ;;
        *) err "Unsupported platform: $PLATFORM"; return 1 ;;
    esac

    local -a newly_installed=()
    for p in "${pre_missing[@]}"; do
        pkg_is_installed "$p" && newly_installed+=("$p")
    done
    track_installed_pkgs "${newly_installed[@]}"
    return "$rc"
}

pac_install() { pkg_install "$@"; }

aur_helper() {
    if has yay; then echo yay; elif has paru; then echo paru; else echo ""; fi
}
