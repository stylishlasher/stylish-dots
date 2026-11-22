#!/usr/bin/env bash
# MangoWC dotfiles install helper for Debian/Ubuntu-based systems.
# Installs available dependencies via apt, then applies dotfiles from this repo.
set -euo pipefail

SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)"

if ! command -v apt-get >/dev/null 2>&1; then
  echo "apt-get not found. This script is for Debian/Ubuntu-based systems." >&2
  exit 1
fi

if [[ $EUID -eq 0 ]]; then
  echo "Run as a regular user (sudo will be requested when needed)." >&2
  exit 1
fi

sudo -v

echo "==> Installing MangoWC-related dependencies (best-effort)..."
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends \
  fuzzel fzf mako-notifier libnotify-bin swaybg waybar \
  grim slurp wl-clipboard cliphist \
  brightnessctl playerctl pavucontrol foot swaylock \
  python3 network-manager || true

# Optional packages (don't fail if unavailable)
for pkg in matugen wlsunset gammastep satty nwg-look; do
  if apt-cache show "$pkg" >/dev/null 2>&1; then
    sudo apt-get install -y --no-install-recommends "$pkg" || true
  else
    echo "skip optional: $pkg (not in apt)"
  fi
done

echo "==> Applying MangoWC dotfiles..."
bash "$SCRIPT_PATH/install.sh"

echo ""
echo "✓ MangoWC dotfiles applied (Debian/Ubuntu helper)."
echo "  Note: the MangoWC compositor package itself may not be in Debian repos;"
echo "  install it from your distro/source if needed."
