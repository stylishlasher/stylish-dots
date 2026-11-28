#!/usr/bin/env bash

DOTFILES_PROFILE="${DOTFILES_PROFILE:-end-4}"
NVIM_PRESET="${NVIM_PRESET:-lazyvim-stylish}"

DOTFILES_UPSTREAM_CLONE_DEPTH="${DOTFILES_UPSTREAM_CLONE_DEPTH:-1}"

dotfiles_profile_name() {
    case "$1" in
        stylish-dots) t profile_stylish ;;
        end-4) t profile_end4 ;;
        caelestia) t profile_caelestia ;;
        serpantinum) t profile_serpantinum ;;
        darkshadowshell) t profile_darkshadowshell ;;
        macshell) t profile_macshell ;;
        mango) t profile_mango ;;
        *) echo "$1" ;;
    esac
}

dotfiles_repo_url() {
    case "$1" in
        end-4) echo "https://github.com/end-4/dots-hyprland.git" ;;
        caelestia) echo "https://github.com/caelestia-dots/caelestia.git" ;;
        darkshadowshell) echo "https://github.com/shadowww-dev/DarkShadowShell.git" ;;
        macshell) echo "https://github.com/0-ss/MacShell.git" ;;
        mango) echo "https://github.com/stylishlasher/stylish-dots.git" ;;
        serpantinum) echo "https://github.com/Serpantinum/dots-hyprland.git" ;;
        *) return 1 ;;
    esac
}

dotfiles_repo_ref() {
    case "$1" in
        end-4) echo "main" ;;
        caelestia) echo "main" ;;
        darkshadowshell) echo "main" ;;
        macshell) echo "main" ;;
        mango) echo "${REPO_BRANCH:-main}" ;;
        serpantinum) echo "main" ;;
        *) echo "main" ;;
    esac
}

dotfiles_backup_targets() {
    local profile="$1"
    case "$profile" in
        end-4)
            printf '%s
'                 "$HOME/.config/hypr/custom"                 "$HOME/.config/hypr/hyprland/keybinds.lua"                 "$HOME/.config/illogical-impulse/config.json"                 "$HOME/.config/environment.d/10-cursor.conf"                 "$HOME/.config/gtk-3.0/settings.ini"                 "$HOME/.config/gtk-4.0/settings.ini"                 "$HOME/.icons/default/index.theme" ;;
        caelestia)
            printf '%s
'                 "$HOME/.config/caelestia"                 "$HOME/.config/quickshell/caelestia"                 "$HOME/.local/state/caelestia" ;;
        mango)
            printf '%s
'                 "$HOME/.config/mango"                 "$HOME/.config/waybar"                 "$HOME/.config/foot"                 "$HOME/.config/fuzzel"                 "$HOME/.config/mako"                 "$HOME/.config/matugen"                 "$HOME/.local/bin/mango-settings" ;;
        stylish-dots)
            printf '%s
'                 "$HOME/.config/fish"                 "$HOME/.config/nvim"                 "$HOME/.config/fastfetch"                 "$HOME/README.md" ;;
        darkshadowshell)
            printf '%s
'                 "$HOME/.config/quickshell/rice-desktop"                 "$HOME/.config/quickshell/rice-settings"                 "$HOME/.config/quickshell/rice-welcome"                 "$HOME/.config/quickshell/hyprquickpaper"                 "$HOME/.config/quickshell/rice-apps"                 "$HOME/.config/hypr/user.lua"                 "$HOME/.local/share/darkshadows-shell" ;;
        macshell)
            printf '%s
'                 "$HOME/.config/quickshell/MacShell"                 "$HOME/.config/quickshell/MacLock"                 "$HOME/.config/hypr-macshell"                 "$HOME/.config/macbar"                 "$HOME/.config/macdock"                 "$HOME/.config/macwidgets"                 "$HOME/.config/macshell" ;;
        serpantinum)
            printf '%s
'                 "$HOME/.local/state/serpantinum"                 "$HOME/.config/quickshell/serpantinum" ;;
        *) return 0 ;;
    esac
}

dotfiles_env_profiles() {
    printf '%s\n' end-4 caelestia mango stylish-dots darkshadowshell macshell serpantinum
}

dotfiles_backup_profile() {
    local profile="$1" tpath
    while IFS= read -r tpath; do
        [[ -n "$tpath" ]] || continue
        stash_dir "$tpath" || return 1
    done < <(dotfiles_backup_targets "$profile")
}

dotfiles_backup_for_swap() {
    local profile="$1" p tpath
    local -A seen=()
    for p in "$profile" $(dotfiles_env_profiles); do
        while IFS= read -r tpath; do
            [[ -n "$tpath" ]] || continue
            [[ -n "${seen[$tpath]+x}" ]] && continue
            seen[$tpath]=1
            stash_dir "$tpath" || return 1
        done < <(dotfiles_backup_targets "$p")
    done
}

dotfiles_clone_upstream() {
    local profile="$1" url ref dest
    url="$(dotfiles_repo_url "$profile")" || return 1
    ref="$(dotfiles_repo_ref "$profile")"
    ensure_work_dir
    dest="$WORK_DIR/upstream-$profile"
    rm -rf "$dest"
    info "$(t dotfiles_upstream_installing "$profile")"
    if ! git clone --depth "$DOTFILES_UPSTREAM_CLONE_DEPTH" --recurse-submodules --shallow-submodules --branch "$ref" "$url" "$dest"; then
        err "$(t dotfiles_upstream_failed "$profile")"
        return 1
    fi
    printf '%s
' "$dest"
}

dotfiles_run_upstream_installer() {
    local profile="$1" repo_dir="$2"
    case "$profile" in
        end-4)
            local installer=""
            if [[ -f "$repo_dir/setup" ]]; then installer="$repo_dir/setup"
            elif [[ -f "$repo_dir/install.sh" ]]; then installer="$repo_dir/install.sh"
            fi
            [[ -n "$installer" ]] || { err "$(t dotfiles_upstream_failed "$profile")"; return 1; }
            chmod +x "$installer" 2>/dev/null || true
            if is_interactive; then
                (cd "$repo_dir" && bash ./setup install) || return 1
            else
                (cd "$repo_dir" && bash ./setup install --force --skip-sysupdate) || return 1
            fi
            ;;
        caelestia)
            if [[ "$PLATFORM" == "arch" ]]; then
                action_install_caelestia || return 1
                return 0
            fi
            warn "$(t caelestia_arch_only)"
            info "$(t caelestia_debian_hint)"
            return 1
            ;;
        darkshadowshell)
            [[ -f "$repo_dir/install.sh" ]] || { err "$(t dotfiles_upstream_failed "$profile")"; return 1; }
            chmod +x "$repo_dir/install.sh" 2>/dev/null || true
            (cd "$repo_dir" && bash ./install.sh --yes) || return 1
            ;;
        macshell)
            [[ -f "$repo_dir/install.sh" ]] || { err "$(t dotfiles_upstream_failed "$profile")"; return 1; }
            chmod +x "$repo_dir/install.sh" 2>/dev/null || true
            (cd "$repo_dir" && bash ./install.sh --yes --no-start --no-gui) || return 1
            ;;
        serpantinum)
            warn "Serpantinum installer is external; run its official installer, then apply themes from config/themes."
            info "Example: curl -fsSL https://install.serpantinum.dev | bash"
            return 1
            ;;
        mango)
            return 0
            ;;
        *) return 1 ;;
    esac
}

dotfiles_apply_profile_config() {
    local profile="$1"
    resolve_configs || return 1
    case "$profile" in
        end-4) action_apply_end4 ;;
        mango) action_apply_mango ;;
        stylish-dots) action_apply_stylish "$NVIM_PRESET" ;;
        caelestia)
            # Caelestia upstream installer handles config; keep hook for local overrides if present.
            if [[ -f "$CONFIGS_DIR/caelestia/install.sh" ]]; then bash "$CONFIGS_DIR/caelestia/install.sh"; else return 0; fi
            ;;
        serpantinum)
            # Themes/presets only; upstream installer is separate.
            if [[ -d "$CONFIGS_DIR/themes" ]]; then info "Serpantinum themes available in $CONFIGS_DIR/themes"; fi
            return 0
            ;;
        darkshadowshell|macshell)
            if [[ -f "$CONFIGS_DIR/$profile/install.sh" ]]; then
                bash "$CONFIGS_DIR/$profile/install.sh"
            else
                info "No local config overlay for $profile; upstream install is the source of truth."
            fi
            ;;
        *) err "Unknown profile: $profile"; return 1 ;;
    esac
}

action_install_dotfiles_profile() {
    local profile="${1:-$DOTFILES_PROFILE}"
    local assume_yes="${2:-}"
    local name repo_dir=""
    name="$(dotfiles_profile_name "$profile")"

    case "$profile" in
        stylish-dots|end-4|caelestia|serpantinum|darkshadowshell|macshell|mango) ;;
        *) err "Unknown profile: $profile"; return 1 ;;
    esac

    if [[ "$profile" == "serpantinum" ]]; then
        warn "Serpantinum installer is external; run its official installer, then apply themes from config/themes."
        info "Example: curl -fsSL https://install.serpantinum.dev | bash"
        return 1
    fi
    if [[ "$profile" == "caelestia" && "$PLATFORM" != "arch" ]]; then
        warn "$(t caelestia_arch_only)"
        info "$(t caelestia_debian_hint)"
        return 1
    fi

    if is_interactive && [[ "$assume_yes" != "--yes" ]]; then
        warn "$(t dotfiles_backup_note)"
        confirm "$(t dotfiles_swap_confirm "$name")" || return 1
    fi

    dotfiles_backup_for_swap "$profile" || return 1

    case "$profile" in
        stylish-dots)
            action_apply_stylish "$NVIM_PRESET" || return 1
            ;;
        mango)
            dotfiles_apply_profile_config mango || return 1
            ;;
        end-4|caelestia|darkshadowshell|macshell)
            if ! repo_dir="$(dotfiles_clone_upstream "$profile")"; then
                err "$(t dotfiles_upstream_failed "$profile")"
                return 1
            fi
            if ! dotfiles_run_upstream_installer "$profile" "$repo_dir"; then
                err "$(t dotfiles_upstream_failed "$profile")"
                return 1
            fi
            if [[ "$profile" == "end-4" ]]; then
                ok "$(t dotfiles_upstream_installed "$profile")"
            fi
            dotfiles_apply_profile_config "$profile" || warn "$(t dotfiles_upstream_failed "$profile")"
            ;;
    esac

    ok "$(t dotfiles_config_applied "$name")"
    ok "$(t dotfiles_swap_done "$name")"
}

apply_mango_config() {
    resolve_configs || return 1
    if [[ -f "$CONFIGS_DIR/mango/install.sh" ]]; then
        bash "$CONFIGS_DIR/mango/install.sh"
        return $?
    fi
    err "MangoWC config not found ($CONFIGS_DIR/mango/install.sh)"; return 1
}

apply_end4_config() {
    resolve_configs || return 1
    if [[ -f "$CONFIGS_DIR/end4/install.sh" ]]; then
        bash "$CONFIGS_DIR/end4/install.sh"
        return $?
    fi
    err "end-4 config not found ($CONFIGS_DIR/end4/install.sh)"; return 1
}

apply_stylish_configs_only() {
    local nvim_choice="${1:-3}"
    require_module actions/fish.sh
    has fish && { apply_fish_config || warn "fish config not applied"; } || warn "$(t fish_missing)"
    if [[ "$nvim_choice" != "3" ]]; then
        require_module actions/neovim.sh
        local preset="lazyvim-stylish"; [[ "$nvim_choice" == "2" ]] && preset="super-easy-casual"
        apply_nvim_config "$preset" || warn "nvim config not applied"
    fi
}

action_apply_stylish_configs_only() { apply_stylish_configs_only "$@"; }

apply_stylish_configs() {
    local preset="${1-$NVIM_PRESET}"
    require_module actions/fish.sh
    require_module actions/neovim.sh
    require_module actions/fetches.sh
    apply_fish_config || warn "fish config not applied"
    action_build_rust_fetches || warn "Rust fetches not built"
    install_fish_plugins || true
    [[ -z "$preset" ]] || apply_nvim_config "$preset" || warn "nvim config not applied"
}

action_apply_mango() { apply_mango_config; }
