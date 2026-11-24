#!/usr/bin/env bash
# Replace the avatar or background of an installed SDDM theme.
set -euo pipefail

theme="${1:-}"
kind="${2:-}"
src="${3:-}"
themes_dir="${SDDM_THEMES_DIR:-$HOME/.local/share/sddm/themes}"

if [[ -z "$theme" || -z "$kind" || -z "$src" ]]; then
    echo "usage: set-image.sh <caelestia|end4|stylish|serpantinum> <avatar|background> <image>" >&2
    exit 1
fi
[[ -f "$src" ]] || { echo "no such file: $src" >&2; exit 1; }

case "$kind" in
    avatar)     name=avatar.png;     size=256 ;;
    background) name=background.png; size="" ;;
    *) echo "unknown image kind: $kind" >&2; exit 1 ;;
esac

dst_dir="$themes_dir/$theme/assets"
[[ -d "$dst_dir" ]] || { echo "theme not installed: $themes_dir/$theme" >&2; exit 1; }

if has_magick=$(command -v magick 2>/dev/null) && [[ -n "$has_magick" ]]; then
    if [[ -n "$size" ]]; then
        "$has_magick" "$src" -resize "${size}x${size}^" -gravity center -extent "${size}x${size}" "$dst_dir/$name"
    else
        "$has_magick" "$src" -resize '1920x1080^' -gravity center -extent 1920x1080 "$dst_dir/$name"
    fi
else
    cp -f -- "$src" "$dst_dir/$name"
fi
printf '%s\n' "$dst_dir/$name"
