#!/usr/bin/env bash

action_uninstall() {
    require_module lib/menu.sh
    require_module actions/preflight.sh
    require_module actions/backup.sh
    action_preflight uninstall || return 1

    local -a items=(
        "rollback-end4|Откатить end4 по бэкапам (или убрать новые пути)|off"
        "rollback-mango|Откатить mango по бэкапам (или убрать новые пути)|off"
        "rollback-stylish|Откатить stylish по бэкапам (или убрать новые пути)|off"
        "fish-conf|Удалить ~/.config/fish|off"
        "nvim-conf|Удалить ~/.config/nvim|off"
        "fastfetch-conf|Удалить ~/.config/fastfetch|off"
        "illogical-conf|Удалить ~/.config/illogical-impulse/quickshell|off"
        "home-readme|Удалить ~/README.md только если создан multitool|off"
        "rust-fetches|Удалить Rust fetch binaries из ~/.local/bin|off"
        "remove-pkgs|Удалить пакеты, установленные этим инсталлером (осторожно)|off"
    )
    select_packages "Uninstall: выбери что удалить/откатить" "${items[@]}" || return 1

    echo
    echo -e "${BOLD}${CYAN}== UNINSTALL OVERVIEW ==${NC}"
    if (( ${#SELECTED_PACKAGES[@]} )); then
        local p; for p in "${SELECTED_PACKAGES[@]}"; do echo "  - $p"; done
    else
        echo "  - (ничего не выбрано)"
    fi
    is_interactive && ! confirm "Продолжить uninstall/rollback?" && return 1

    local failed=0 okc=0
    for p in "${SELECTED_PACKAGES[@]}"; do
        case "$p" in
            rollback-end4) if action_restore_profile end4; then okc=$((okc+1)); else warn "rollback end4 failed"; failed=$((failed+1)); fi ;;
            rollback-mango) if action_restore_profile mango; then okc=$((okc+1)); else warn "rollback mango failed"; failed=$((failed+1)); fi ;;
            rollback-stylish) if action_restore_profile stylish; then okc=$((okc+1)); else warn "rollback stylish failed"; failed=$((failed+1)); fi ;;
            fish-conf) if stash_dir "$HOME/.config/fish"; then ok "fish config removed"; okc=$((okc+1)); else failed=$((failed+1)); fi ;;
            nvim-conf) if stash_dir "$HOME/.config/nvim"; then ok "nvim config removed"; okc=$((okc+1)); else failed=$((failed+1)); fi ;;
            fastfetch-conf) if stash_dir "$HOME/.config/fastfetch"; then ok "fastfetch config removed"; okc=$((okc+1)); else failed=$((failed+1)); fi ;;
            illogical-conf) if stash_dir "$HOME/.config/illogical-impulse/quickshell"; then ok "quickshell config removed"; okc=$((okc+1)); else failed=$((failed+1)); fi ;;
            home-readme)
                local f="$HOME/README.md"
                if [[ -f "$f" ]] && grep -q "stylish-dots:home-readme" "$f"; then
                    if stash_dir "$f"; then ok "home README removed/backed up"; okc=$((okc+1)); else failed=$((failed+1)); fi
                else
                    warn "~/README.md не помечен как созданный multitool; пропущен"
                fi
                ;;
            rust-fetches)
                local b rf=0; for b in keyfetch treefetch tomatofetch stoolfetch skeletonfetch; do
                    [[ -f "$HOME/.local/bin/$b" ]] || continue
                    stash_dir "$HOME/.local/bin/$b" || rf=1
                done
                if (( rf )); then failed=$((failed+1)); else ok "rust fetch binaries removed/backed up"; okc=$((okc+1)); fi ;;
            remove-pkgs)
                ensure_sudo || { failed=$((failed+1)); continue; }
                local state="${XDG_STATE_HOME:-$HOME/.local/state}/stylish-dots/installed-packages.txt"
                local -a pkgs=()
                if [[ -f "$state" ]]; then
                    mapfile -t pkgs < <(grep -v '^#' "$state" | sed '/^$/d')
                else
                    warn "Нет списка пакетов, установленных installer-ом ($state). Пропускаю удаление пакетов."
                    continue
                fi
                (( ${#pkgs[@]} )) || { warn "Список установленных пакетов пуст"; continue; }
                echo "Будут удалены только пакеты из $state:"
                printf '  - %s\n' "${pkgs[@]}"
                is_interactive && ! confirm "Удалить эти пакеты?" && continue
                if [[ "$PLATFORM" == "arch" ]]; then
                    sudo pacman -Rns --noconfirm "${pkgs[@]}" || { warn "some packages not removed"; failed=$((failed+1)); continue; }
                else
                    sudo apt-get remove -y "${pkgs[@]}" || { warn "some packages not removed"; failed=$((failed+1)); continue; }
                fi
                okc=$((okc+1)) ;;
        esac
    done
    if (( failed )); then err "Uninstall завершён с ошибками: ok=$okc fail=$failed"; return 1; fi
    ok "Uninstall завершён: $okc действий. Бэкапы в $BACKUP_REGISTRY"
}
