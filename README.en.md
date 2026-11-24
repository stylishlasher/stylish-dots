# stylish-dots

🇷🇺 [Русский](README.md) · 🇬🇧 English · 🇷🇴 [Română](README.ro.md)

Personal dotfiles and an installer for Arch Linux: **end-4 / illogical-impulse** (Hyprland + Quickshell), **fish**, **Neovim presets**, Serpantinum themes, MangoWC, and the all-in-one `arch_multitool.sh`.

> **Credit to end-4:** the `end4/` profile is my personal configuration/add-ons on top of [**end-4/dots-hyprland** (illogical-impulse)](https://github.com/end-4/dots-hyprland). The original project, the base shell/architecture, and all credit for dots-hyprland belong to [end-4](https://github.com/end-4).

The repository is self-contained: you can apply the configs manually or through the multitool. The script can read configs from the local repository folder or download them from GitHub.

- **Repo:** https://github.com/stylishlasher/stylish-dots/
- **GitHub Pages:** https://stylishlasher.github.io/stylish-dots/
- **Bio (my Telegram channel, DMs, and other Roblox stuff are there):**
https://lislash.vercel.app/
---

## Contents

- [What's inside](#whats-inside)
- [Quick start](#quick-start)
- [Dotfiles profiles](#dotfiles-profiles)
- [Neovim presets](#neovim-presets)
- [Repository structure](#repository-structure)
- [Where configs are applied](#where-configs-are-applied)
- [end-4 / illogical-impulse](#end-4--illogical-impulse)
- [MangoWC](#mangowc)
- [Custom fetches](#custom-fetches)
- [GitHub Pages](#github-pages)
- [Credits](#credits)
- [License](#license)

---

## What's inside

- **`config/end4/`** — my current config for end-4/dots-hyprland (illogical-impulse): custom Hyprland overrides, patched `hyprland/keybinds.lua`, Quickshell `illogical-impulse/config.json`, cursor/GTK/env.
- **`config/fish/`** — the current fish config.
- **`config/nvim/`** — the active Neovim config (LazyVim, `lazyvim-stylish`).
- **`config/nvim-presets/`** — Neovim preset choices:
  - `lazyvim-stylish/` — a new, polished LazyVim setup;
  - `super-easy-casual/` — the old lightweight config from a previous commit.
- **`config/themes/`** — JSON presets/Serpantinum themes.
- **`config/fetches/stylish-fetches/`** — Rust rewrite of the former unstable C fetches (3D fetches, run manually by command).
- **`config/fastfetch/presets/`** — fastfetch presets: `default`, `mine`, `micro`, `stylish`, `universal`.
- **`config/mango/`, `config/waybar/`, `config/foot/`, `config/fuzzel/`, `config/mako/`, `config/matugen/`, `config/bin/`** — MangoWC/Wayland dotfiles and utilities.
- **`docs/`** — custom GitHub Pages site in Material You style.
- **`arch_multitool.sh`** — GUI/menu multitool (Arch), **`arch_multitool_debian.sh`** — Debian/Ubuntu adaptation.
- **`modules/`** — action modules: the multitool provides the UI, while installing/applying configs is handled by the modules (downloaded on demand).

---

## Quick start

### Arch Linux (primary)

One command (no repo cloning):

```bash
curl -fsSL https://raw.githubusercontent.com/stylishlasher/stylish-dots/main/install/install.sh | bash
```

From a cloned repo:

```bash
git clone https://github.com/stylishlasher/stylish-dots.git
cd stylish-dots
bash install/install.sh
```

### Debian / Ubuntu-based (adapted version)

One command (no repo cloning):

```bash
curl -fsSL https://raw.githubusercontent.com/stylishlasher/stylish-dots/main/install/install_debian.sh | bash
```

From a cloned repo:

```bash
git clone https://github.com/stylishlasher/stylish-dots.git
cd stylish-dots
bash install/install_debian.sh
```

> Both multitools are GUI/menu shells: the logic lives in `modules/`. The bootstrap installers (`install/install.sh`, `install/install_debian.sh`) place the launchers, `modules/` and `config/` into `~/.local/share/arch-multitool`, so everything works offline after the first run; `bash install/install.sh --refresh` (or `install_debian.sh --refresh`) refreshes the cache. Direct launcher runs are disabled: they only print a hint and require the bootstrap.
> The Arch version targets pacman/AUR; the Debian version is best-effort for apt/dpkg.
>
> The bundle manifest (`bundle.sha256`) is RSA-signed: the public key is embedded in both `install/*.sh`, the private key never enters the repository. SHA-256 of every file, file permissions and symlinks are verified, so swapping files together with the manifest won't pass. After changes to `modules/` or `config/`, re-sign it with `bash scripts/sign-bundle.sh` (private key via `STYLISH_SIGNING_KEY` or `~/.local/share/stylish-dots/signing.key`). Only `install/*.sh` itself is unsigned — it is fetched over HTTPS.
>
> это уже паранойя, но комфорт юзера - главное

---

## Dotfiles profiles

The **full interactive install** (menu option 1) is a four-step wizard: dotfiles profile, software, configs and presets, then a summary with confirmation. Everything is optional: nothing is installed unless you tick it, and the profile can be skipped. The "SDDM theme for profile" checkbox installs only the theme matching your chosen dots; if no profile is picked, a separate question asks which theme to use.

| Profile | What it does |
|---|---|
| **Caelestia** | `caelestia-cli` from the AUR + `caelestia install` (Arch only; upstream picks components). |
| **end-4 / illogical-impulse** | Applies my current config from `end4/` on top of an installed dots-hyprland. |
| **serpantinum** | Runs the external Serpantinum installer (via its own installer); themes/presets can be applied from `config/themes/`. |
| **stylish-dots** | Applies my dotfiles: fish, Neovim preset, fastfetch preset, Rust 3D fetches. |

Software menu options 6-11 install SDDM, Caelestia, Bibata Modern Classic / Modern Ice cursors (GTK, X11, Qt, Hyprland), set monitors to their maximum refresh rate via `hyprctl`, `wlr-randr` or `xrandr`, and copy four SDDM themes (one per profile: `caelestia`, `end4`, `stylish`, `serpantinum`) into `~/.local/share/sddm/themes` without root. Option 11 changes a theme's avatar or background: `config/sddm-themes/set-image.sh <theme> <avatar|background> <path>`. For the real login screen copy the themes together with `_assets` to `/usr/share/sddm/themes` and set `Current=` in `/etc/sddm.conf.d/`; preview with `sddm-greeter-qt6 --test-mode --theme ~/.local/share/sddm/themes/stylish`. Main menu option 9, "Clear script cache", removes `~/.local/share/arch-multitool` after confirmation; restore it with `bash install/install.sh` (or `install_debian.sh`). On Debian Caelestia is best-effort: upstream supports Arch only.

---

## Neovim presets

When installing Neovim (option **6**) or using the `stylish-dots` profile, you can choose a preset:

| Preset | Description |
|---|---|
| **lazyvim-stylish** | New, polished LazyVim: Snacks UI, noice, neo-tree, treesitter extras, the `dots` theme (Material You from quickshell), RU langmap, cheatsheet. |
| **super-easy-casual** | Old simple config from a previous commit, a single `init.lua`. |

Cheatsheet: `nvim/cheatsheet.md`; in Neovim, press `F1`, `<leader>H`, or `:Cheat`.

---

## Repository structure

```text
stylish-dots/
├── arch_multitool.sh        # Arch GUI multitool (loads modules/)
├── arch_multitool_debian.sh # Debian/Ubuntu GUI multitool
├── modules/                 # action modules (downloaded on demand)
│   ├── lib/                 # common/platform/menu/loader
│   └── actions/             # fish, neovim, fetches, dotfiles, software, interactive...
├── install/
│   ├── install.sh           # Arch bootstrap (curl | bash)
│   └── install_debian.sh    # Debian/Ubuntu bootstrap
├── config/                  # all configs/assets (to keep the root clean)
│   ├── end4/                # my current end-4 / illogical-impulse config
│   │   ├── hypr/
│   │   ├── illogical-impulse/
│   │   ├── gtk-3.0/ gtk-4.0/
│   │   ├── environment.d/
│   │   └── install.sh
│   ├── fish/                # active fish config
│   ├── nvim/                # active LazyVim config
│   ├── nvim-presets/
│   │   ├── lazyvim-stylish/
│   │   └── super-easy-casual/
│   ├── themes/              # JSON presets/Serpantinum themes
│   ├── fetches/
│   │   ├── unstable/        # old C sources (legacy, not used by default)
│   │   └── stylish-fetches/ # Rust 3D fetches (keyfetch/treefetch/tomatofetch/stoolfetch/skeletonfetch)
│   ├── fastfetch/presets/   # default/mine/micro/stylish/universal
│   ├── mango/               # MangoWC configs
│   ├── waybar/ foot/ fuzzel/ mako/ matugen/ bin/
├── docs/                    # GitHub Pages (Material You)
│   └── install.txt          # Serpantinum install command (optional)
├── README.md
└── LICENSE.md
```

---

## Where configs are applied

| What | Where |
|---|---|
| end-4 / illogical-impulse | `~/.config/hypr/custom/`, `~/.config/hypr/hyprland/keybinds.lua`, `~/.config/illogical-impulse/config.json`, `~/.config/environment.d/`, GTK/cursor files |
| fish | `~/.config/fish/` |
| Neovim preset | `~/.config/nvim/` |
| MangoWC | `~/.config/mango/`, `~/.config/waybar/`, `~/.config/foot/`, `~/.config/fuzzel/`, `~/.config/mako/`, `~/.config/matugen/`, `~/.local/bin/mango-settings` |
| Serpantinum themes | `~/.local/state/serpantinum/presets/` |
| Stylish 3D fetches (Rust) | `~/.local/bin/{keyfetch,treefetch,tomatofetch,stoolfetch,skeletonfetch}` |
| Console pranks | `~/.local/bin/{csorting,hackerlarp}`, `~/.config/fish/functions/csorting.fish` |

> Before replacing existing configs, the multitool/scripts make a backup (`*.bak.<timestamp>` or a backup directory).

> **Important:** API keys are not stored in the repository. AI keys for illogical-impulse are added through the UI and saved in the keyring.

---

## end-4 / illogical-impulse

**Credits:** [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) by [end-4](https://github.com/end-4) — the original project. `config/end4/` in this repository contains **my** custom overrides/config on top of it, not a replacement for the original.

My active config lives in `config/end4/` and is installed separately:

```bash
cd stylish-dots
bash config/end4/install.sh
```

Or via the multitool: option **17** or the **end-4 / stylish-dots** profile.

What it includes:
- `hypr/custom/*.lua` — monitor/layout/env/rules/execs;
- `hypr/hyprland/keybinds.lua` — patch for Print/screenshots;
- `illogical-impulse/config.json` — shell/AI prefs (no API keys);
- Bibata cursor, GTK settings, `environment.d/10-cursor.conf`.

> [dots-hyprland / illogical-impulse](https://github.com/end-4/dots-hyprland) must be installed before applying.

---

## MangoWC

MangoWC dotfiles are still in the repo and are installed via multitool option **16** or `mango/install.sh`.

```bash
cd stylish-dots
bash config/mango/install.sh
```

---

## Custom fetches

The Rust 3D fetches live in `config/fetches/stylish-fetches/` and are run manually: `keyfetch`, `treefetch`, `tomatofetch`, `stoolfetch`, `skeletonfetch`. Rotation modes: `--rotate horizontal|vertical|random`.

The old C sources are kept in `config/fetches/unstable/` as legacy/abandoned.

## Fastfetch presets

`config/fastfetch/presets/` contains the presets: `default`, `mine`, `micro`, `stylish`, `universal`. The multitool can install the chosen preset to `~/.config/fastfetch/config.jsonc` (backing up the old one).

## Fish/CLI utilities (extras)

Utilities added in `config/bin/` and `config/fish/functions/`:

- `fakefetch` — fake fastfetch/neofetch for distros: `fakefetch -l arch -s stylish|original|mini|ultra|neon|box`
- `styletext` — ASCII art text: `styletext "hello"`, `styletext --random-font "hello"`, `styletext -F border "hi"` (figlet/toilet if available)
- `converttool` — file converter (ffmpeg/imagemagick/pandoc when available): `converttool in.png out.webp`, `converttool *.wav .mp3 --batch`
- `clipkeep` — clipboard history (wl-copy/wl-paste/xclip): `clipkeep save`, `clipkeep list`, `clipkeep copy 1`
- `quicknote` — quick notes in `~/Notes/quicknotes.md`: `quicknote "text"`, `quicknote -l`, `quicknote -s word`
- Fish functions: `mkcd`, `extract`, `servehere`, `fire`, `clipkeep`, `quicknote`
- Extra fish aliases: `.. ... .... gs ga gc gp gl gdiff myip ports ll lt path please`

## HackerLARP (terminal prank)

`config/bin/hackerlarp` — a customizable rofl/larp Hollywood simulator for the terminal. **No real hacking**: only fake animations/output.

- Modules: `banner`, `scan`, `bruteforce`, `decrypt`, `download`, `exploit`, `exfil`, `matrix`, `wifi`, `trace`, `sqlinject`, `ddos`, `bitcoin`, `camera`, `git`, `docker`, `phishing`, `wipe`, `compile`, `satellite`, `firewall`, `ssh_tunnel`
- Configuration: `~/.config/hackerlarp/config.json` (speed, theme, modules, targets, wordlist, files, loop/duration/seed, `show_disclaimer`)
- Flags: `--no-disclaimer` hides the simulation/fake notices, `--disclaimer` turns them back on
- Example config: `config/bin/hackerlarp.config.example.json`

Run locally:

```bash
python3 config/bin/hackerlarp --write-config
python3 config/bin/hackerlarp --theme amber --speed 1.2 --modules banner,scan,bruteforce,wifi,bitcoin,matrix
python3 config/bin/hackerlarp --no-disclaimer --once
```

Install via the multitool: **Console pranks → LARP / movie hacker (hackerlarp)**.

## csorting (ambient sorting)

`config/bin/csorting` is a lightweight sorting visualizer with no dependencies (Python stdlib only). In circle mode the dots start scattered across the terminal and gather into an even gradient ring as the sort advances; bars fill the terminal width and grow vertically from small to large. Every operation is drawn as its own frame; once the array is sorted it is shuffled again and the next algorithm takes over. The title shows operation counts for the current and all runs plus the gather percentage.

- Views: `--circle` (scattered dots gathering into an even ring) and `--line` (bars, default)
- Algorithms: `bubble`, `cocktail`, `gnome`, `insertion`, `selection`, `shell`, `comb`, `oddeven`, `quick`, `heap`, `merge`
- `--algorithm all` (default) cycles through them; `--algorithm shell` or the positional form `csorting --circle shell` pins one
- Color: without `--color` it uses matugen from `~/.local/state/quickshell/user/generated/colors.json` (or `$MATUGEN_COLORS_FILE`), falling back to `rainbow`. The gradient is a smooth 24-bit RGB interpolation between stops
- `--color ocean|fire|ice|mono|rainbow|matugen` picks a palette, `--color '#ff0000,#00ff00,#0000ff'` sets custom stops; `--palettes` lists them
- Exit: `Ctrl+C`, `Ctrl+D`, `q` or `Esc`
- Algorithm and gradient check: `python3 config/bin/csorting --self-test`

```bash
csorting --circle
csorting --line --algorithm gnome --delay 0.02
csorting --circle shell
csorting --circle --color fire
csorting --line --color '#13140c,#c6cc7a,#e5e3d6'
```

Install via the multitool: **Console pranks → csorting** (copied to `~/.local/bin`, fish function to `~/.config/fish/functions`).

---

## Recommendations

- **Wallpaper pack:** [Wallpaper Pack 25 (TMS Wallpapers) — 4K 3840x2160](https://forums.tms.sx/threads/wallpaper-pack-25-tms-wallpapers-4k-3840x2160-1-1000.40932/)
- **Firefox extensions:**
  - [Dark Reader](https://addons.mozilla.org/ru/firefox/addon/darkreader/)
  - [uBlock Origin](https://addons.mozilla.org/ru/firefox/addon/ublock-origin/)
  - [DuckDuckGo Privacy Essentials](https://addons.mozilla.org/ru/firefox/addon/duckduckgo-for-firefox/)
  - [Privacy Badger](https://addons.mozilla.org/ru/firefox/addon/privacy-badger17/)
  - [SponsorBlock](https://addons.mozilla.org/ru/firefox/addon/sponsorblock/)

---

## GitHub Pages

The site lives in `docs/` and is deployed by GitHub Pages from the `main` branch, folder `/docs`.

To enable:
1. Repo **Settings → Pages**
2. **Build and deployment → Source: Deploy from a branch**
3. **Branch: `main` / Folder: `/docs`**

Site: https://stylishlasher.github.io/stylish-dots/

---

## Credits

- **[end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)** by [end-4](https://github.com/end-4) — the original illogical-impulse / dots-hyprland project, the base shell architecture, and huge work on the ecosystem. My `config/end4/` is just custom overrides on top of it.
- **[Serpantinum](https://github.com/ilyamiro/serpantinum)** by [Illia Miroshnichenko (@ilyamiro)](https://github.com/ilyamiro) — the Wayland environment/presets/themes used by the `serpantinum` profile and part of the theme/preset flow in the multitool. Site: https://serpantinum.dev.

---

## License

This repository is distributed under the **GNU AGPL-3.0** license (see [LICENSE.md](LICENSE.md)).
