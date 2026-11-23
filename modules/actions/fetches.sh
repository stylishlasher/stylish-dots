#!/usr/bin/env bash

FASTFETCH_PRESETS=(default mine micro stylish universal)

fastfetch_preset_desc() {
    case "$1" in
        default) echo "Стандартный";;
        mine) echo "Как у меня (компактный)";;
        micro) echo "Микро (4 строки)";;
        stylish) echo "Стайлиш (иконки)";;
        universal) echo "Универсал (макс инфо)";;
        *) echo "$1";;
    esac
}

action_install_fastfetch_preset() {
    local preset="${1:-mine}"
    resolve_configs || return 1
    local src="$CONFIGS_DIR/fastfetch/presets/${preset}.jsonc"
    [[ -f "$src" ]] || { err "Preset not found: $preset"; return 1; }
    has fastfetch || { ensure_sudo || return 1; pkg_install fastfetch || true; }
    mkdir -p "$HOME/.config/fastfetch"
    local dst="$HOME/.config/fastfetch/config.jsonc"
    [[ -f "$dst" ]] && cp -a "$dst" "${dst}.bak.$(date +%Y%m%d_%H%M%S)"
    cp -a "$src" "$dst"
    ok "Fastfetch preset '$preset' установлен."
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
    ok "Rust 3D fetches установлены."
}

action_fetches_menu() {
    require_module lib/menu.sh
    while true; do
        menu_select "Фетчи" \
            "1|Fastfetch пресеты" \
            "2|Собрать/установить Rust 3D fetches" \
            "0|Назад" || return 0
        case "$MENU_CHOICE" in
            1)
                local -a items=() i=1 p; for p in "${FASTFETCH_PRESETS[@]}"; do items+=("$i|$p — $(fastfetch_preset_desc "$p")"); i=$((i+1)); done; items+=("0|Назад")
                menu_select "Fastfetch preset" "${items[@]}" || true
                [[ "$MENU_CHOICE" == "0" ]] && continue
                action_install_fastfetch_preset "${FASTFETCH_PRESETS[$((MENU_CHOICE-1))]}"
                ;;
            2) action_build_rust_fetches ;;
            0) return 0 ;;
        esac
    done
}
