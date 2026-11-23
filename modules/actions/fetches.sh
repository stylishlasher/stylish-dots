#!/usr/bin/env bash

FASTFETCH_PRESETS=(default mine micro stylish universal)

fastfetch_preset_desc() {
    case "$1" in
        default) t preset_default;;
        mine) t preset_mine;;
        micro) t preset_micro;;
        stylish) t preset_stylish;;
        universal) t preset_universal;;
        *) echo "$1";;
    esac
}

action_copy_fastfetch_preset() {
    local preset="${1:-mine}"
    resolve_configs || return 1
    local src="$CONFIGS_DIR/fastfetch/presets/${preset}.jsonc"
    [[ -f "$src" ]] || { err "Preset not found: $preset"; return 1; }
    mkdir -p "$HOME/.config/fastfetch"
    local dst="$HOME/.config/fastfetch/config.jsonc"
    [[ -f "$dst" || -L "$dst" ]] && stash_dir "$dst"
    cp -a "$src" "$dst"
    ok "$(t preset_copied "$preset")"
}

action_install_fastfetch_preset() {
    local preset="${1:-mine}"
    has fastfetch || { ensure_sudo || return 1; pkg_install fastfetch || true; }
    action_copy_fastfetch_preset "$preset"
}

RUST_FETCHES=(keyfetch treefetch tomatofetch stoolfetch skeletonfetch)
action_build_rust_fetches() {
    resolve_configs || return 1
    local src="$CONFIGS_DIR/fetches/stylish-fetches"
    [[ -f "$src/Cargo.toml" ]] || { err "Rust fetches source missing"; return 1; }
    has cargo || { ensure_sudo || return 1; pkg_install cargo rustc || pkg_install rust cargo || true; }
    (cd "$src" && cargo build --release) || return 1
    mkdir -p "$HOME/.local/bin"
    local f
    for f in "${RUST_FETCHES[@]}"; do install -m 0755 "$src/target/release/$f" "$HOME/.local/bin/$f"; done
    ok "$(t rust_fetches_installed)"
}

action_fetches_menu() {
    require_module lib/menu.sh
    while true; do
        menu_select "$(t fetches)" \
            "1|$(t fetches_presets)" \
            "2|$(t fetches_build)" \
            "0|$(t menu_back)" || return 0
        case "$MENU_CHOICE" in
            1)
                local -a items=() i=1 p; for p in "${FASTFETCH_PRESETS[@]}"; do items+=("$i|$p — $(fastfetch_preset_desc "$p")"); i=$((i+1)); done; items+=("0|$(t menu_back)")
                menu_select "Fastfetch preset" "${items[@]}" || true
                [[ "$MENU_CHOICE" == "0" ]] && continue
                action_install_fastfetch_preset "${FASTFETCH_PRESETS[$((MENU_CHOICE-1))]}"
                ;;
            2) action_build_rust_fetches ;;
            0) return 0 ;;
        esac
    done
}
