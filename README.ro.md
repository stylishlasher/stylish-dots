# stylish-dots

🇷🇺 [Русский](README.md) · 🇬🇧 [English](README.en.md) · 🇷🇴 Română

Dotfile-uri personale și un instalator pentru Arch Linux: **end-4 / illogical-impulse** (Hyprland + Quickshell), **fish**, **Neovim presets**, teme Serpantinum, MangoWC și utilitarul universal `arch_multitool.sh`.

> **Meritul lui end-4:** profilul `end4/` reprezintă configurația mea personală/extensiile mele peste [**end-4/dots-hyprland** (illogical-impulse)](https://github.com/end-4/dots-hyprland). Proiectul original, shell-ul și arhitectura de bază, precum și meritul pentru dots-hyprland îi aparțin [end-4](https://github.com/end-4).

Depozitul este autonom: configurațiile pot fi aplicate manual sau prin utilitar. Scriptul poate lua configurațiile din dosarul local al depozitului sau le poate descărca de pe GitHub.

- **Repo:** https://github.com/stylishlasher/stylish-dots/
- **GitHub Pages:** https://stylishlasher.github.io/stylish-dots/
- **Bio (acolo găsești canalul meu de Telegram, mesajele private și alte chestii Roblox):**
https://lislash.vercel.app/
---

## Cuprins

- [Ce conține](#ce-conține)
- [Pornire rapidă](#pornire-rapidă)
- [Profiluri dotfiles](#profiluri-dotfiles)
- [Neovim presets](#neovim-presets)
- [Structura depozitului](#structura-depozitului)
- [Unde se aplică configurațiile](#unde-se-aplică-configurațiile)
- [end-4 / illogical-impulse](#end-4--illogical-impulse)
- [MangoWC](#mangowc)
- [Fetch-uri personalizate](#fetch-uri-personalizate)
- [GitHub Pages](#github-pages)
- [Mulțumiri](#mulțumiri)
- [Licență](#licență)

---

## Ce conține

- **`config/end4/`** — configurația mea actuală pentru end-4/dots-hyprland (illogical-impulse): suprascrieri personalizate Hyprland, `hyprland/keybinds.lua` modificat, `illogical-impulse/config.json` pentru Quickshell, cursor/GTK/env.
- **`config/fish/`** — configurația fish actuală.
- **`config/nvim/`** — configurația Neovim activă (LazyVim, `lazyvim-stylish`).
- **`config/nvim-presets/`** — selecția de preseturi Neovim:
  - `lazyvim-stylish/` — un setup LazyVim nou, elaborat;
  - `super-easy-casual/` — configurația ușoară veche dintr-un commit anterior.
- **`config/themes/`** — preseturi JSON/teme Serpantinum.
- **`config/fetches/stylish-fetches/`** — rescrierea în Rust a vechilor fetch-uri C instabile (fetch-uri 3D, rulate manual prin comandă).
- **`config/fastfetch/presets/`** — preseturi fastfetch: `default`, `mine`, `micro`, `stylish`, `universal`.
- **`config/mango/`, `config/waybar/`, `config/foot/`, `config/fuzzel/`, `config/mako/`, `config/matugen/`, `config/bin/`** — dotfile-uri și utilități MangoWC/Wayland.
- **`docs/`** — site GitHub Pages personalizat în stil Material You.
- **`arch_multitool.sh`** — utilitar GUI/cu meniu (Arch), **`arch_multitool_debian.sh`** — adaptare pentru Debian/Ubuntu.
- **`modules/`** — module de acțiuni: utilitarul oferă interfața, iar instalarea/aplicarea configurațiilor se face prin module (descărcate la nevoie).

---

## Pornire rapidă

### Arch Linux (principal)

O singură comandă (fără clonarea depozitului):

```bash
curl -fsSL https://raw.githubusercontent.com/stylishlasher/stylish-dots/main/install/install.sh | bash
```

Din depozitul clonat:

```bash
git clone https://github.com/stylishlasher/stylish-dots.git
cd stylish-dots
bash install/install.sh
```

### Debian / Ubuntu-based (versiune adaptată)

O singură comandă (fără clonarea depozitului):

```bash
curl -fsSL https://raw.githubusercontent.com/stylishlasher/stylish-dots/main/install/install_debian.sh | bash
```

Din depozitul clonat:

```bash
git clone https://github.com/stylishlasher/stylish-dots.git
cd stylish-dots
bash install/install_debian.sh
```

> Ambele utilitare sunt interfețe GUI/cu meniu: logica se află în `modules/`. Instalatoarele bootstrap (`install/install.sh`, `install/install_debian.sh`) pun launcherele, `modules/` și `config/` în `~/.local/share/arch-multitool`, deci totul funcționează offline după prima rulare; `bash install/install.sh --refresh` (sau `install_debian.sh --refresh`) actualizează cache-ul. Rularea directă a launcherelor este dezactivată: acestea doar afișează o sugestie și necesită bootstrapul.
> Versiunea Arch vizează pacman/AUR; versiunea Debian este o încercare de tip best-effort pentru apt/dpkg.
>
> Manifestul setului (`bundle.sha256`) este semnat RSA: cheia publică este încorporată în ambele `install/*.sh`, iar cheia privată nu ajunge în repository. Se verifică SHA-256 al fiecărui fișier, permisiunile și legăturile simbolice, deci înlocuirea fișierelor împreună cu manifestul nu trece. După modificări în `modules/` sau `config/`, resemnează cu `bash scripts/sign-bundle.sh` (cheia privată: `STYLISH_SIGNING_KEY` sau `~/.local/share/stylish-dots/signing.key`). Numai `install/*.sh` rămâne nesemnat — el se descarcă prin HTTPS.
>
> это уже паранойя, но комфорт юзера - главное

---

## Profiluri dotfiles

**Instalarea interactivă completă** (opțiunea 1) este un asistent în patru pași: profilul dotfiles, software-ul, configurațiile și presetările, apoi un rezumat cu confirmare. Totul este opțional: nimic nu se instalează fără bifă, iar profilul poate fi omis.

| Profil | Ce face |
|---|---|
| **Caelestia** | `caelestia-cli` din AUR + `caelestia install` (doar Arch; componentele le alege proiectul upstream). |
| **end-4 / illogical-impulse** | Aplică configurația mea actuală din `end4/` peste dots-hyprland instalat. |
| **serpantinum** | Rulează instalatorul extern Serpantinum (prin instalatorul său); temele/preseturile pot fi aplicate din `config/themes/`. |
| **stylish-dots** | Aplică dotfile-urile mele: fish, preset Neovim, preset fastfetch, fetch-uri 3D în Rust. |

Opțiunile 6-11 din meniul Software instalează SDDM, Caelestia, cursoarele Bibata Modern Classic / Modern Ice (GTK, X11, Qt, Hyprland), configurează monitoarele la rata maximă prin `hyprctl`, `wlr-randr` sau `xrandr` și copiază patru teme SDDM (câte una per profil: `caelestia`, `end4`, `stylish`, `serpantinum`) în `~/.local/share/sddm/themes`, fără root. Opțiunea 11 schimbă avatarul sau fundalul temei: `config/sddm-themes/set-image.sh <temă> <avatar|background> <cale>`. Pentru ecranul de login copiază temele împreună cu `_assets` în `/usr/share/sddm/themes` și setează `Current=` în `/etc/sddm.conf.d/`; previzualizezi cu `sddm-greeter-qt6 --test-mode --theme ~/.local/share/sddm/themes/stylish`. Opțiunea 9 din meniul principal, "Șterge cache-ul scriptului", elimină `~/.local/share/arch-multitool` după confirmare; îl recreezi cu `bash install/install.sh` (sau `install_debian.sh`). Pe Debian Caelestia este best-effort: upstream acceptă doar Arch.

---

## Neovim presets

La instalarea Neovim (opțiunea **6**) sau în profilul `stylish-dots`, poți alege un preset:

| Preset | Descriere |
|---|---|
| **lazyvim-stylish** | LazyVim nou, elaborat: Snacks UI, noice, neo-tree, extra-uri treesitter, tema `dots` (Material You din quickshell), langmap RU, fișă de referință. |
| **super-easy-casual** | Configurația simplă veche dintr-un commit anterior, un singur `init.lua`. |

Fișă de referință: `nvim/cheatsheet.md`; în Neovim apasă `F1`, `<leader>H` sau `:Cheat`.

---

## Structura depozitului

```text
stylish-dots/
├── arch_multitool.sh        # utilitar GUI Arch (încarcă modules/)
├── arch_multitool_debian.sh # utilitar GUI Debian/Ubuntu
├── modules/                 # module de acțiuni (descărcate la nevoie)
│   ├── lib/                 # common/platform/menu/loader
│   └── actions/             # fish, neovim, fetches, dotfiles, software, interactive...
├── install/
│   ├── install.sh           # bootstrap Arch (curl | bash)
│   └── install_debian.sh    # bootstrap Debian/Ubuntu
├── config/                  # toate configurațiile/resursele (ca să nu aglomerăm rădăcina)
│   ├── end4/                # configurația mea actuală end-4 / illogical-impulse
│   │   ├── hypr/
│   │   ├── illogical-impulse/
│   │   ├── gtk-3.0/ gtk-4.0/
│   │   ├── environment.d/
│   │   └── install.sh
│   ├── fish/                # configurația fish activă
│   ├── nvim/                # configurația LazyVim activă
│   ├── nvim-presets/
│   │   ├── lazyvim-stylish/
│   │   └── super-easy-casual/
│   ├── themes/              # preseturi JSON/teme Serpantinum
│   ├── fetches/
│   │   ├── unstable/        # vechile surse C (legacy, nu sunt folosite implicit)
│   │   └── stylish-fetches/ # fetch-uri 3D în Rust (keyfetch/treefetch/tomatofetch/stoolfetch/skeletonfetch)
│   ├── fastfetch/presets/   # default/mine/micro/stylish/universal
│   ├── mango/               # configurații MangoWC
│   ├── waybar/ foot/ fuzzel/ mako/ matugen/ bin/
├── docs/                    # GitHub Pages (Material You)
│   └── install.txt          # comanda de instalare Serpantinum (opțional)
├── README.md
└── LICENSE.md
```

---

## Unde se aplică configurațiile

| Ce | Unde |
|---|---|
| end-4 / illogical-impulse | `~/.config/hypr/custom/`, `~/.config/hypr/hyprland/keybinds.lua`, `~/.config/illogical-impulse/config.json`, `~/.config/environment.d/`, fișiere GTK/cursor |
| fish | `~/.config/fish/` |
| Preset Neovim | `~/.config/nvim/` |
| MangoWC | `~/.config/mango/`, `~/.config/waybar/`, `~/.config/foot/`, `~/.config/fuzzel/`, `~/.config/mako/`, `~/.config/matugen/`, `~/.local/bin/mango-settings` |
| Teme Serpantinum | `~/.local/state/serpantinum/presets/` |
| Fetch-uri 3D Stylish (Rust) | `~/.local/bin/{keyfetch,treefetch,tomatofetch,stoolfetch,skeletonfetch}` |

> Înainte de a înlocui configurațiile existente, utilitarul/scripturile fac o copie de siguranță (`*.bak.<timestamp>` sau un dosar backup).

> **Important:** cheile API nu sunt stocate în depozit. Cheile AI pentru illogical-impulse se adaugă prin interfață și se salvează în keyring.

---

## end-4 / illogical-impulse

**Merituri:** [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) de [end-4](https://github.com/end-4) — proiectul original. `config/end4/` din acest depozit conține **suprascrierile/configurația mea** personală peste el, nu o înlocuire a originalului.

Configurația mea activă se află în `config/end4/` și se instalează separat:

```bash
cd stylish-dots
bash config/end4/install.sh
```

Sau prin utilitar: opțiunea **17** sau profilul **end-4 / stylish-dots**.

Ce include:
- `hypr/custom/*.lua` — monitor/layout/env/rules/execs;
- `hypr/hyprland/keybinds.lua` — patch pentru Print/capturi de ecran;
- `illogical-impulse/config.json` — preferințe shell/AI (fără chei API);
- cursor Bibata, setări GTK, `environment.d/10-cursor.conf`.

> [dots-hyprland / illogical-impulse](https://github.com/end-4/dots-hyprland) trebuie instalat înainte de aplicare.

---

## MangoWC

Dotfile-urile MangoWC se află în continuare în depozit și se instalează prin opțiunea **16** a utilitarului sau prin `mango/install.sh`.

```bash
cd stylish-dots
bash config/mango/install.sh
```

---

## Fetch-uri personalizate

Fetch-urile 3D în Rust se află în `config/fetches/stylish-fetches/` și se rulează manual: `keyfetch`, `treefetch`, `tomatofetch`, `stoolfetch`, `skeletonfetch`. Moduri de rotație: `--rotate horizontal|vertical|random`.

Vechile surse C sunt păstrate în `config/fetches/unstable/` ca legacy/abandonate.

## Preseturi fastfetch

`config/fastfetch/presets/` conține preseturi: `default`, `mine`, `micro`, `stylish`, `universal`. Utilitarul poate instala presetul ales în `~/.config/fastfetch/config.jsonc` (cu copie de siguranță a celui vechi).

## Utilități Fish/CLI (extra)

Utilități adăugate în `config/bin/` și `config/fish/functions/`:

- `fakefetch` — fastfetch/neofetch fals pentru distribuții: `fakefetch -l arch -s stylish|original|mini|ultra|neon|box`
- `styletext` — text ASCII art: `styletext "hello"`, `styletext --random-font "hello"`, `styletext -F border "hi"` (figlet/toilet dacă sunt disponibile)
- `converttool` — convertor de fișiere (ffmpeg/imagemagick/pandoc dacă sunt disponibile): `converttool in.png out.webp`, `converttool *.wav .mp3 --batch`
- `clipkeep` — istoricul clipboardului (wl-copy/wl-paste/xclip): `clipkeep save`, `clipkeep list`, `clipkeep copy 1`
- `quicknote` — note rapide în `~/Notes/quicknotes.md`: `quicknote "text"`, `quicknote -l`, `quicknote -s cuvânt`
- Funcții fish: `mkcd`, `extract`, `servehere`, `fire`, `clipkeep`, `quicknote`
- Alias-uri suplimentare în fish: `.. ... .... gs ga gc gp gl gdiff myip ports ll lt path please`

## HackerLARP (glumă în terminal)

`config/bin/hackerlarp` — un simulator Hollywood rofl/larp personalizabil pentru terminal. **Niciun hack real**: doar animații/outputuri false.

- Module: `banner`, `scan`, `bruteforce`, `decrypt`, `download`, `exploit`, `exfil`, `matrix`, `wifi`, `trace`, `sqlinject`, `ddos`, `bitcoin`, `camera`, `git`, `docker`, `phishing`, `wipe`, `compile`, `satellite`, `firewall`, `ssh_tunnel`
- Configurare: `~/.config/hackerlarp/config.json` (viteză, temă, module, ținte, wordlist, fișiere, loop/duration/seed, `show_disclaimer`)
- Opțiuni: `--no-disclaimer` ascunde mesajele despre simulare/fals, `--disclaimer` le reactivează
- Config exemplu: `config/bin/hackerlarp.config.example.json`

Rulează local:

```bash
python3 config/bin/hackerlarp --write-config
python3 config/bin/hackerlarp --theme amber --speed 1.2 --modules banner,scan,bruteforce,wifi,bitcoin,matrix
python3 config/bin/hackerlarp --no-disclaimer --once
```

Instalare prin utilitar: **Glume în consolă → LARP / hacker de film (hackerlarp)**.

---

## Recomandări

- **Pachet de tapete:** [Wallpaper Pack 25 (TMS Wallpapers) — 4K 3840x2160](https://forums.tms.sx/threads/wallpaper-pack-25-tms-wallpapers-4k-3840x2160-1-1000.40932/)
- **Extensii Firefox:**
  - [Dark Reader](https://addons.mozilla.org/ru/firefox/addon/darkreader/)
  - [uBlock Origin](https://addons.mozilla.org/ru/firefox/addon/ublock-origin/)
  - [DuckDuckGo Privacy Essentials](https://addons.mozilla.org/ru/firefox/addon/duckduckgo-for-firefox/)
  - [Privacy Badger](https://addons.mozilla.org/ru/firefox/addon/privacy-badger17/)
  - [SponsorBlock](https://addons.mozilla.org/ru/firefox/addon/sponsorblock/)

---

## GitHub Pages

Site-ul se află în `docs/` și este publicat prin GitHub Pages din ramura `main`, dosarul `/docs`.

Pentru activare:
1. Repo **Settings → Pages**
2. **Build and deployment → Source: Deploy from a branch**
3. **Branch: `main` / Folder: `/docs`**

Site: https://stylishlasher.github.io/stylish-dots/

---

## Mulțumiri

- **[end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)** de [end-4](https://github.com/end-4) — proiectul original illogical-impulse / dots-hyprland, arhitectura shell de bază și munca uriașă depusă în ecosistem. `config/end4/` al meu conține doar suprascrieri personalizate peste el.
- **[Serpantinum](https://github.com/ilyamiro/serpantinum)** de [Illia Miroshnichenko (@ilyamiro)](https://github.com/ilyamiro) — mediul Wayland/preseturile/temele folosite de profilul `serpantinum` și de o parte din fluxul theme/preset al utilitarului. Site: https://serpantinum.dev.

---

## Licență

Acest depozit este distribuit sub licența **GNU AGPL-3.0** (vezi [LICENSE.md](LICENSE.md)).
