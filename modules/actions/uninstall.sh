#!/usr/bin/env bash

action_uninstall() {
    require_module lib/menu.sh
    require_module actions/preflight.sh
    require_module actions/backup.sh
    action_preflight uninstall || return 1

    local -a items=(
        "fish-conf|Удалить ~/.config/fish|off"
        "nvim-conf|Удалить ~/.config/nvim|off"
        "fastfetch-conf|Удалить ~/.config/fastfetch|off"
        "illogical-conf|Удалить ~/.config/illogical-impulse/quickshell|off"
        "home-readme|Удалить ~/README.md (созданный multitool)|off"
        "rust-fetches|Удалить Rust fetch binaries из ~/.local/bin|off"
        "remove-pkgs|Удалить базовые пакеты (осторожно)|off"
    )
    select_packages "Uninstall: выбери что удалить" "${items[@]}" || return 1

    echo
    echo -e "${BOLD}${CYAN}== UNINSTALL OVERVIEW ==${NC}"
    if (( ${#SELECTED_PACKAGES[@]} )); then
        local p; for p in "${SELECTED_PACKAGES[@]}"; do echo "  - $p"; done
    else
        echo "  - (ничего не выбрано)"
    fi
    is_interactive && ! confirm "Продолжить удаление?" && return 1

    for p in "${SELECTED_PACKAGES[@]}"; do
        case "$p" in
            fish-conf) stash_dir "$HOME/.config/fish"; ok "fish config removed" ;;
            nvim-conf) stash_dir "$HOME/.config/nvim"; ok "nvim config removed" ;;
            fastfetch-conf) stash_dir "$HOME/.config/fastfetch"; ok "fastfetch config removed" ;;
            illogical-conf) stash_dir "$HOME/.config/illogical-impulse/quickshell"; ok "quickshell config removed" ;;
            home-readme) [[ -f "$HOME/README.md" ]] && { stash_dir "$HOME/README.md"; ok "home README removed"; } ;;
            rust-fetches)
                local b; for b in keyfetch treefetch tomatofetch stoolfetch skeletonfetch; do
                    [[ -f "$HOME/.local/bin/$b" ]] && { stash_dir "$HOME/.local/bin/$b"; }
                done
                ok "rust fetch binaries removed/backed up" ;;
            remove-pkgs)
                ensure_sudo || return 1
                if [[ "$PLATFORM" == "arch" ]]; then
                    sudo pacman -Rns --noconfirm fastfetch fish neovim 2>/dev/null || warn "some packages not removed"
                else
                    sudo apt-get remove -y fastfetch fish neovim 2>/dev/null || warn "some packages not removed"
                fi
                ;;
        esac
    done
    ok "Uninstall завершён. Бэкапы в $BACKUP_REGISTRY"
}
