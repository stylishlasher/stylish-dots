#!/usr/bin/env bash

apply_fish_config() {
    resolve_configs || return 1
    local src="$CONFIGS_DIR/fish" dst="$HOME/.config/fish"
    [[ -d "$src" ]] || { err "$(t fish_no_src "$src")"; return 1; }
    stash_dir "$dst"; mkdir -p "$dst"
    local item
    for item in config.fish fish_plugins conf.d functions completions themes auto-Hypr.fish; do
        [[ -e "$src/$item" ]] && cp -a "$src/$item" "$dst/"
    done
    normalize_paths "$dst"
    ok "$(t fish_config_applied)"
}

install_fish_plugins() {
    has fish || return 0
    fish -c 'functions -q fisher; and fisher update' 2>/dev/null \
      || fish -c "fisher install $FISH_PLUGINS" 2>/dev/null \
      || warn "$(t fish_plugins_failed)"
}

set_default_shell_fish() {
    has fish || return 0
    local fsh; fsh=$(command -v fish)
    [[ "${SHELL:-}" == "$fsh" ]] && return 0
    if is_interactive && confirm "$(t fish_default_prompt)"; then
        chsh -s "$fsh" || warn "$(t chsh_failed)"
    fi
}

action_install_fish() {
    ensure_sudo || return 1
    pkg_install fish
    apply_fish_config || true
    install_fish_plugins || true
    set_default_shell_fish || true
    ok "$(t fish_ready)"
}
