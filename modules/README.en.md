# modules/

🇷🇺 [Русский](../README.md) · 🇬🇧 English · 🇷🇴 [Română](README.ro.md)

The modular system of stylish-dots. The multitools (`arch_multitool.sh`, `arch_multitool_debian.sh`) handle the UI/menu, while the actions live in modules.

## Structure

- `lib/` — shared helpers:
  - `common.sh` — logging, sudo, resolve_configs, backup/normalize
  - `platform.sh` — platform detection and pkg_install/pkg_update
  - `menu.sh` — menu_select/select_packages
  - `loader.sh` — module download/sourcing, run_action
- `actions/` — actions:
  - `interactive.sh` — full install: four-step wizard
  - `software.sh` — software menu
  - `extras.sh` — SDDM, Caelestia, Bibata cursors, monitors, cache cleanup
  - `dotfiles.sh` — applying profiles/configs
  - `fish.sh`, `neovim.sh`, `fetches.sh`, `flatpak.sh`, `network.sh`, `system.sh`, `audit.sh`

## How it works

When the multitool starts, it loads `lib/*`. When the user picks an action, `run_action` sources the right `actions/*.sh`. If the module isn't available locally (e.g. with `curl | bash`), the loader downloads it from `https://raw.githubusercontent.com/stylishlasher/stylish-dots/main/modules/...`.

## Extending

Add a new action in `modules/actions/<name>.sh`, export an `action_*` function, and register it in `modules/lib/loader.sh` under `run_action`.
