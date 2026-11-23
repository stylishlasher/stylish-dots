#!/usr/bin/env bash
# Install end-4/dots-hyprland (illogical-impulse) user config from this repo.
# Safe to run repeatedly: backs up existing targets.
set -euo pipefail

SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_PATH/.." && pwd)"
# Locate payload: script in config/end4, or repo root with config/end4 or end4
if [ -d "$SCRIPT_PATH/hypr" ] && [ -d "$SCRIPT_PATH/illogical-impulse" ]; then
  SRC="$SCRIPT_PATH"
elif [ -d "$SCRIPT_PATH/config/end4" ]; then
  ROOT="$SCRIPT_PATH"; SRC="$ROOT/config/end4"
elif [ -d "$SCRIPT_PATH/end4" ]; then
  ROOT="$SCRIPT_PATH"; SRC="$ROOT/end4"
else
  echo "Cannot locate end4 config payload." >&2
  exit 1
fi

TS="$(date +%Y%m%d_%H%M%S_%N)_$$"
BK="$HOME/.config-backup-end4-$TS"
BACKED_UP=0

BACKUP_REGISTRY="${XDG_STATE_HOME:-$HOME/.local/state}/stylish-dots/backups.tsv"
register_backup() {
  local src="$1" bk="$2"
  mkdir -p "$(dirname "$BACKUP_REGISTRY")"
  printf '%s	%s	%s
' "$(date '+%F %T')" "$src" "$bk" >> "$BACKUP_REGISTRY"
}

backup_path() {
  local target="$1" rel="$2"
  if [ -e "$target" ] || [ -L "$target" ]; then
    mkdir -p "$BK/$(dirname "$rel")"
    cp -a "$target" "$BK/$rel"
    register_backup "$target" "$BK/$rel"
    BACKED_UP=1
    echo "backup: $target -> $BK/$rel"
  fi
}

copy_file() {
  local src="$1" dst="$2" rel="$3" mode="${4:-}"
  [ -f "$src" ] || return 0
  backup_path "$dst" "$rel"
  mkdir -p "$(dirname "$dst")"
  install -m "${mode:-644}" "$src" "$dst"
  echo "installed: $dst"
}

copy_dir_merge() {
  local src="$1" dst="$2" rel="$3"
  [ -d "$src" ] || return 0
  backup_path "$dst" "$rel"
  mkdir -p "$dst"
  cp -a "$src/." "$dst/"
  echo "installed dir: $dst"
}

echo "=== Installing end-4 dots config from $SRC ==="

# Hyprland custom overrides (user-owned, safe)
copy_dir_merge "$SRC/hypr/custom" "$HOME/.config/hypr/custom" "hypr/custom"

# Patched upstream keybinds - keep a backup; only apply if upstream file exists
if [ -f "$SRC/hypr/hyprland/keybinds.lua" ] && [ -f "$HOME/.config/hypr/hyprland/keybinds.lua" ]; then
  backup_path "$HOME/.config/hypr/hyprland/keybinds.lua" "hypr/hyprland/keybinds.lua"
  install -m 644 "$SRC/hypr/hyprland/keybinds.lua" "$HOME/.config/hypr/hyprland/keybinds.lua"
  echo "installed: ~/.config/hypr/hyprland/keybinds.lua (patched Print binds)"
elif [ -f "$SRC/hypr/hyprland/keybinds.lua" ]; then
  echo "skip: ~/.config/hypr/hyprland/keybinds.lua (upstream not installed yet)"
fi

# Quickshell / illogical-impulse config
copy_file "$SRC/illogical-impulse/config.json" "$HOME/.config/illogical-impulse/config.json" "illogical-impulse/config.json"

# Cursor/env/gtk
copy_file "$SRC/environment.d/10-cursor.conf" "$HOME/.config/environment.d/10-cursor.conf" "environment.d/10-cursor.conf"
copy_file "$SRC/gtk-3.0/settings.ini" "$HOME/.config/gtk-3.0/settings.ini" "gtk-3.0/settings.ini"
copy_file "$SRC/gtk-4.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini" "gtk-4.0/settings.ini"
copy_file "$SRC/icons-default/index.theme" "$HOME/.icons/default/index.theme" "icons-default/index.theme"

# Permissions
chmod +x "$HOME/.config/hypr/custom/scripts/"* 2>/dev/null || true

# Apply live where possible
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
  command -v hyprctl >/dev/null 2>&1 && hyprctl reload >/dev/null 2>&1 || true
  command -v hyprctl >/dev/null 2>&1 && hyprctl setcursor Bibata-Modern-Classic 24 >/dev/null 2>&1 || true
fi

if [ "$BACKED_UP" = 0 ] && [ -d "$BK" ]; then
  rmdir "$BK" 2>/dev/null || true
fi

echo ""
echo "✓ end-4 config installed."
echo "  Backups: ${BK} (if created)"
echo "  Notes:"
echo "   - hypr/custom/* applied (monitor, ru layout, cursor env, Print binds)"
echo "   - illogical-impulse config.json applied (top bar always, bottom dock hover, AI enabled)"
echo "   - Re-login may be needed for cursor env.d/GTK changes in all apps."
