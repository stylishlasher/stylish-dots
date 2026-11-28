#!/usr/bin/env bash

action_uninstall() {
    require_module lib/menu.sh
    require_module actions/preflight.sh
    require_module actions/backup.sh
    action_preflight uninstall || return 1

    local -a items=(
        "rollback-end4|$(t rollback_end4)|off"
        "rollback-mango|$(t rollback_mango)|off"
        "rollback-stylish|$(t rollback_stylish)|off"
        "rollback-caelestia|Rollback caelestia|off"
        "rollback-serpantinum|Rollback Serpantinum|off"
        "fish-conf|$(t uninstall_fish)|off"
        "nvim-conf|$(t uninstall_nvim)|off"
        "fastfetch-conf|$(t uninstall_fastfetch)|off"
        "illogical-conf|$(t uninstall_quickshell)|off"
        "home-readme|$(t uninstall_readme)|off"
        "rust-fetches|$(t uninstall_fetches)|off"
        "remove-pkgs|$(t uninstall_pkgs)|off"
    )
    select_packages "$(t uninstall_select)" "${items[@]}" || return 1

    echo
    echo -e "${BOLD}${CYAN}== UNINSTALL OVERVIEW ==${NC}"
    if (( ${#SELECTED_PACKAGES[@]} )); then
        local p; for p in "${SELECTED_PACKAGES[@]}"; do echo "  - $p"; done
    else
        echo "  - $(t nothing_selected)"
    fi
    is_interactive && ! confirm "$(t confirm_uninstall)" && return 1

    local failed=0 okc=0
    for p in "${SELECTED_PACKAGES[@]}"; do
        case "$p" in
            rollback-end4) if action_restore_profile end4; then okc=$((okc+1)); else warn "rollback end4 failed"; failed=$((failed+1)); fi ;;
            rollback-mango) if action_restore_profile mango; then okc=$((okc+1)); else warn "rollback mango failed"; failed=$((failed+1)); fi ;;
            rollback-stylish) if action_restore_profile stylish; then okc=$((okc+1)); else warn "rollback stylish failed"; failed=$((failed+1)); fi ;;
            rollback-caelestia) if action_restore_profile caelestia; then okc=$((okc+1)); else warn "rollback caelestia failed"; failed=$((failed+1)); fi ;;
            rollback-darkshadowshell) if action_restore_profile darkshadowshell; then okc=$((okc+1)); else warn "rollback darkshadowshell failed"; failed=$((failed+1)); fi ;;
            rollback-macshell) if action_restore_profile macshell; then okc=$((okc+1)); else warn "rollback macshell failed"; failed=$((failed+1)); fi ;;
            rollback-serpantinum) if action_restore_profile serpantinum; then okc=$((okc+1)); else warn "rollback serpantinum failed"; failed=$((failed+1)); fi ;;
            fish-conf) if stash_dir "$HOME/.config/fish"; then ok "fish config removed"; okc=$((okc+1)); else failed=$((failed+1)); fi ;;
            nvim-conf) if stash_dir "$HOME/.config/nvim"; then ok "nvim config removed"; okc=$((okc+1)); else failed=$((failed+1)); fi ;;
            fastfetch-conf) if stash_dir "$HOME/.config/fastfetch"; then ok "fastfetch config removed"; okc=$((okc+1)); else failed=$((failed+1)); fi ;;
            illogical-conf) if stash_dir "$HOME/.config/illogical-impulse/quickshell"; then ok "quickshell config removed"; okc=$((okc+1)); else failed=$((failed+1)); fi ;;
            home-readme)
                local f="$HOME/README.md"
                if [[ -f "$f" ]] && grep -q "stylish-dots:home-readme" "$f"; then
                    if stash_dir "$f"; then ok "home README removed/backed up"; okc=$((okc+1)); else failed=$((failed+1)); fi
                else
                    warn "$(t readme_unmarked)"
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
                    warn "$(t no_pkg_state "$state")"
                    continue
                fi
                (( ${#pkgs[@]} )) || { warn "$(t pkg_state_empty)"; continue; }
                echo "$(t pkgs_to_remove "$state")"
                printf '  - %s\n' "${pkgs[@]}"
                is_interactive && ! confirm "$(t confirm_remove_pkgs)" && continue
                if [[ "$PLATFORM" == "arch" ]]; then
                    sudo pacman -Rns --noconfirm "${pkgs[@]}" || { warn "some packages not removed"; failed=$((failed+1)); continue; }
                else
                    sudo apt-get remove -y "${pkgs[@]}" || { warn "some packages not removed"; failed=$((failed+1)); continue; }
                fi
                okc=$((okc+1)) ;;
        esac
    done
    if (( failed )); then err "$(t uninstall_failed "$okc" "$failed")"; return 1; fi
    ok "$(t uninstall_done "$okc" "$BACKUP_REGISTRY")"
}
