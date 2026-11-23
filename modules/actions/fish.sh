#!/usr/bin/env bash

apply_fish_config() {
    resolve_configs || return 1
    local src="$CONFIGS_DIR/fish" dst="$HOME/.config/fish"
    [[ -d "$src" ]] || { err "Нет $src"; return 1; }
    stash_dir "$dst"; mkdir -p "$dst"
    local item
    for item in config.fish fish_plugins conf.d functions completions themes auto-Hypr.fish; do
        [[ -e "$src/$item" ]] && cp -a "$src/$item" "$dst/"
    done
    normalize_paths "$dst"
    ok "Fish config применён."
}

install_fish_plugins() {
    has fish || return 0
    fish -c 'functions -q fisher; and fisher update' 2>/dev/null \
      || fish -c "fisher install $FISH_PLUGINS" 2>/dev/null \
      || warn "Не удалось установить fish plugins автоматически."
}

set_default_shell_fish() {
    has fish || return 0
    local fsh; fsh=$(command -v fish)
    [[ "${SHELL:-}" == "$fsh" ]] && return 0
    if is_interactive && confirm "Сделать fish shell по умолчанию?"; then
        chsh -s "$fsh" || warn "chsh не удался."
    fi
}

action_install_fish() {
    ensure_sudo || return 1
    pkg_install fish
    apply_fish_config || true
    install_fish_plugins || true
    set_default_shell_fish || true
    ok "Fish готов. 3D fetches запускаются вручную командами keyfetch/treefetch/..."
}
