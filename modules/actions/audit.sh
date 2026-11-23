#!/usr/bin/env bash

action_quick_audit() {
    echo -e "${BOLD}== Быстрый аудит ==${NC}"
    echo "Host: $(hostname 2>/dev/null || echo unknown)"
    echo "OS: $(. /etc/os-release 2>/dev/null; echo "${PRETTY_NAME:-unknown}")"
    echo "Kernel: $(uname -r)"
    echo "Disk:"; df -h / | tail -1
    echo "Mem:"; free -h | awk '/Mem:/ {print $3 "/" $2}'
    if has pacman; then echo "Pacman pkgs: $(pacman -Qq 2>/dev/null | wc -l)"; fi
    if has dpkg; then echo "DPKG pkgs: $(dpkg -l 2>/dev/null | grep -c '^ii')"; fi
    if has flatpak; then echo "Flatpak apps: $(flatpak list --app 2>/dev/null | wc -l)"; fi
}
