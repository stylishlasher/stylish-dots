#!/usr/bin/env bash

action_create_home_readme() {
    local f="$HOME/README.md"
    [[ -e "$f" || -L "$f" ]] && stash_dir "$f"
    cat > "$f" <<MD
<!-- stylish-dots:home-readme -->
# $(t readme_useful_links)

## $(t readme_wallpapers)
- [Wallpaper Pack 25 (TMS Wallpapers) — 4K 3840x2160](https://forums.tms.sx/threads/wallpaper-pack-25-tms-wallpapers-4k-3840x2160-1-1000.40932/)

## $(t readme_extensions)
- [Dark Reader](https://addons.mozilla.org/ru/firefox/addon/darkreader/)
- [uBlock Origin](https://addons.mozilla.org/ru/firefox/addon/ublock-origin/)
- [DuckDuckGo Privacy Essentials](https://addons.mozilla.org/ru/firefox/addon/duckduckgo-for-firefox/)
- [Privacy Badger](https://addons.mozilla.org/ru/firefox/addon/privacy-badger17/)
- [SponsorBlock](https://addons.mozilla.org/ru/firefox/addon/sponsorblock/)
MD
    ok "$(t home_readme_created "$f")"
}

# Необязательные «по желанию» действия: SDDM, Caelestia, курсоры, мониторы, кэш.
BIBATA_VERSION="${BIBATA_VERSION:-2.0.7}"
BIBATA_THEMES=(Bibata-Modern-Classic Bibata-Modern-Ice)

action_install_sddm() {
    require_module actions/system.sh
    ensure_sudo || return 1
    pkg_install sddm || return 1
    action_install_sddm_themes || warn "$(t sddm_theme_failed)"
    if is_interactive && confirm "$(t sddm_enable_prompt)"; then
        sudo systemctl enable sddm.service || warn "$(t sddm_enable_failed)"
    fi
    ok "$(t sddm_ready)"
    info "$(t sddm_hint)"
}

action_install_sddm_themes() {
    local src="${CONFIGS_DIR:-${REPO_ROOT:-$PWD}/config}/sddm-themes"
    [[ -d "$src" ]] || { warn "$(t sddm_themes_missing)"; return 1; }
    local dst="$HOME/.local/share/sddm/themes" name
    mkdir -p "$dst" || return 1
    stash_dir "$dst/_assets" || return 1
    cp -a "$src/_assets" "$dst/" || return 1
    for name in caelestia end4 stylish serpantinum; do
        stash_dir "$dst/$name" || return 1
        cp -a "$src/$name" "$dst/" || return 1
    done
    ok "$(t sddm_themes_ready "$dst")"
}

action_set_sddm_image() {
    require_module lib/menu.sh
    local -a names=(caelestia end4 stylish serpantinum)
    menu_select "$(t sddm_theme_select)" \
        "1|$(t profile_caelestia)" \
        "2|$(t profile_end4)" \
        "3|$(t profile_stylish)" \
        "4|$(t profile_serpantinum)" || return 1
    local theme="${names[$((MENU_CHOICE-1))]}"
    menu_select "$(t sddm_image_select)" \
        "1|$(t sddm_image_avatar)" \
        "2|$(t sddm_image_background)" || return 1
    local kind=avatar; [[ "$MENU_CHOICE" == "2" ]] && kind=background
    local src
    read -rp "$(t sddm_image_prompt): " src || return 1
    [[ -f "$src" ]] || { warn "$(t sddm_image_missing)"; return 1; }
    local script="${CONFIGS_DIR:-${REPO_ROOT:-$PWD}/config}/sddm-themes/set-image.sh"
    [[ -f "$script" ]] || script="$HOME/.local/share/arch-multitool/current/config/sddm-themes/set-image.sh"
    bash "$script" "$theme" "$kind" "$src" || { warn "$(t sddm_image_failed)"; return 1; }
    ok "$(t sddm_image_done "$theme")"
}

action_install_caelestia() {
    require_module actions/system.sh
    ensure_sudo || return 1
    if [[ "$PLATFORM" != "arch" ]]; then
        warn "$(t caelestia_arch_only)"
        info "$(t caelestia_debian_hint)"
        return 1
    fi
    local helper; helper="$(aur_helper)"
    if [[ -z "$helper" ]]; then
        action_install_aur_helper yay || return 1
        helper=yay
    fi
    pkg_install caelestia-cli || return 1
    has caelestia || { err "$(t caelestia_missing)"; return 1; }
    # Апстрим выбирает компоненты сам; --aur-helper нужен для AUR-зависимостей.
    caelestia install --aur-helper "$helper" || warn "$(t caelestia_install_failed)"
    ok "$(t caelestia_ready)"
}

action_install_bibata() {
    if [[ "$PLATFORM" == "arch" ]]; then
        [[ -n "$(aur_helper)" ]] || warn "$(t aur_missing_hint)"
        pkg_install bibata-cursor-theme-bin || return 1
    else
        pkg_install bibata-cursor-theme || return 1
    fi
    local icon_dir="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
    mkdir -p "$icon_dir" || return 1
    local theme archive
    for theme in "${BIBATA_THEMES[@]}"; do
        [[ -d "$icon_dir/$theme" || -d "/usr/share/icons/$theme" ]] && continue
        archive="$icon_dir/$theme.tar.xz"
        if ! curl -fsSL "https://github.com/ful1e5/Bibata_Cursor/releases/download/v${BIBATA_VERSION}/${theme}.tar.xz" -o "$archive"; then
            warn "$(t bibata_download_failed "$theme")"; continue
        fi
        if ! tar -xJf "$archive" -C "$icon_dir"; then
            warn "$(t bibata_download_failed "$theme")"; continue
        fi
        rm -f "$archive"
    done
    ok "$(t bibata_installed)"
}

apply_bibata_theme() {
    local theme="${1:-}"
    [[ -z "$theme" || "$theme" == "none" ]] && return 0
    case "$theme" in
        Bibata-Modern-Classic|Bibata-Modern-Ice) ;;
        *) err "$(t cursor_unknown "$theme")"; return 1 ;;
    esac

    has gsettings && { gsettings set org.gnome.desktop.interface cursor-theme "$theme" || true; gsettings set org.gnome.desktop.interface cursor-size 24 || true; }
    mkdir -p "$HOME/.icons/default" "$HOME/.config/gtk-3.0" || return 1
    stash_dir "$HOME/.icons/default/index.theme" || return 1
    stash_dir "$HOME/.gtkrc-2.0" || return 1
    stash_dir "$HOME/.config/gtk-3.0/settings.ini" || return 1
    printf '[Icon Theme]\nInherits=%s\n' "$theme" > "$HOME/.icons/default/index.theme"
    printf 'gtk-cursor-theme-name="%s"\n' "$theme" > "$HOME/.gtkrc-2.0"
    printf '[Settings]\ngtk-cursor-theme-name=%s\n' "$theme" > "$HOME/.config/gtk-3.0/settings.ini"

    local xr="$HOME/.Xresources" tmp
    touch "$xr" || return 1
    tmp="$(mktemp)" || return 1
    grep -vE '^Xcursor\.(theme|size):' "$xr" > "$tmp" || true
    printf 'Xcursor.theme: %s\nXcursor.size: 24\n' "$theme" >> "$tmp"
    mv -f "$tmp" "$xr" || return 1
    if has xrdb && [[ -n "${DISPLAY:-}" ]]; then xrdb -merge "$xr" || true; fi

    # Qt не имеет своего параметра курсора; qt5ct/qt6ct меняем только если они уже используются.
    local cfg tool
    for tool in qt5ct qt6ct; do
        cfg="$HOME/.config/$tool/$tool.conf"
        [[ -f "$cfg" ]] || continue
        if grep -q '^cursor_theme=' "$cfg"; then
            sed -i "s|^cursor_theme=.*|cursor_theme=$theme|" "$cfg"
        elif grep -q '^\[Appearance\]' "$cfg"; then
            sed -i "/^\[Appearance\]/a cursor_theme=$theme" "$cfg"
        else
            printf '\n[Appearance]\ncursor_theme=%s\n' "$theme" >> "$cfg"
        fi
    done

    local vars="$HOME/.config/caelestia/hypr-vars.lua"
    if [[ -f "$vars" ]]; then
        warn "$(t caelestia_cursor_manual "$vars" "$theme")"
    elif [[ -d "${vars%/*}" ]]; then
        printf 'return {\n    cursorTheme = "%s",\n    cursorSize = 24,\n}\n' "$theme" > "$vars"
    fi
    ok "$(t cursor_applied "$theme")"
}
action_apply_bibata_theme() { apply_bibata_theme "$@"; }

action_cursors_menu() {
    require_module lib/menu.sh
    menu_select "$(t cursor_theme)" \
        "1|$(t cursor_classic)" \
        "2|$(t cursor_ice)" \
        "3|$(t cursor_none)" \
        "0|$(t menu_back)" || return 0
    local theme=""
    case "$MENU_CHOICE" in
        1) theme=Bibata-Modern-Classic ;;
        2) theme=Bibata-Modern-Ice ;;
        3|0) return 0 ;;
    esac
    action_install_bibata || return 1
    apply_bibata_theme "$theme"
    pause
}

action_setup_monitors() {
    local backend=""
    if has hyprctl && hyprctl monitors >/dev/null 2>&1; then backend=hypr
    elif has wlr-randr && wlr-randr >/dev/null 2>&1; then backend=wlr
    elif has xrandr; then backend=xrandr
    else warn "$(t monitors_no_tool)"; return 1; fi

    local parsed out mode rate lines=""
    case "$backend" in
        hypr)
            parsed="$(hyprctl monitors all | awk '
                /^Monitor / {o=$2}
                /availableModes:/ {
                    for(i=2;i<=NF;i++){ m=$i; sub(/^.*@/,"",m); sub(/Hz.*$/,"",m); if(m+0>hz){hz=m+0; best=$i} }
                    if(best!=""){print o " " best; hz=0; best=""}
                }')"
            [[ -n "$parsed" ]] || { warn "$(t monitors_none)"; return 1; }
            while read -r out mode; do
                [[ -n "$out" ]] || continue
                hyprctl keyword monitor "$out, highrr, auto, 1" || warn "$(t monitor_set_failed "$out")"
                lines+="monitor = $out, highrr, auto, 1"$'\n'
                info "$(t monitor_detected "$out" "$mode")"
            done <<< "$parsed"
            local conf="$HOME/.config/hypr/monitors.conf"
            mkdir -p "${conf%/*}" || return 1
            stash_dir "$conf" || return 1
            printf '%s' "$lines" > "$conf"
            info "$(t monitors_hypr_hint "$conf")"
            ;;
        wlr)
            parsed="$(wlr-randr | awk '
                /^[^[:space:]]/ {o=$1}
                / px, [0-9.]+ Hz/ {res=$1; hz=$3; if(hz+0>m){m=hz+0; best=o " " res "@" hz "Hz"}}
                END{if(best!="") print best}')"
            [[ -n "$parsed" ]] || { warn "$(t monitors_none)"; return 1; }
            while read -r out mode; do
                [[ -n "$out" ]] || continue
                wlr-randr --output "$out" --mode "$mode" || warn "$(t monitor_set_failed "$out")"
                info "$(t monitor_detected "$out" "$mode")"
            done <<< "$parsed"
            ;;
        xrandr)
            parsed="$(xrandr --current | awk '
                / connected/ {if(o!="" && m>0) print o " " mode " " rate; o=$1; m=0; mode=""; rate=""}
                /^[[:space:]]*[0-9]+x[0-9]+/ {for(i=2;i<=NF;i++){r=$i; gsub(/[*+]/,"",r); if(r+0>m && r+0>0){m=r+0; mode=$1; rate=r}}}
                END{if(o!="" && m>0) print o " " mode " " rate}')"
            [[ -n "$parsed" ]] || { warn "$(t monitors_none)"; return 1; }
            local tmp xprof="$HOME/.xprofile"
            tmp="$(mktemp)" || return 1
            awk '/^# stylish-dots:monitors-start$/{skip=1} !skip{print} /^# stylish-dots:monitors-end$/{skip=0}' "$xprof" 2>/dev/null > "$tmp" || true
            echo '# stylish-dots:monitors-start' >> "$tmp"
            while read -r out mode rate; do
                [[ -n "$out" ]] || continue
                xrandr --output "$out" --mode "$mode" --rate "$rate" || warn "$(t monitor_set_failed "$out")"
                printf 'xrandr --output %s --mode %s --rate %s\n' "$out" "$mode" "$rate" >> "$tmp"
                info "$(t monitor_detected "$out" "${mode}@${rate}Hz")"
            done <<< "$parsed"
            echo '# stylish-dots:monitors-end' >> "$tmp"
            mv -f "$tmp" "$xprof" || return 1
            ;;
    esac
    ok "$(t monitors_ready)"
}

action_clear_cache() {
    local dir="${XDG_DATA_HOME:-$HOME/.local/share}/arch-multitool"
    [[ -d "$dir" ]] || { warn "$(t cache_absent "$dir")"; return 0; }
    is_interactive && ! confirm "$(t confirm_clear_cache "$dir")" && return 1
    rm -rf -- "$dir/current" "$dir/releases" || return 1
    ok "$(t cache_cleared)"
    warn "$(t cache_rebootstrap)"
}
