# stylish-dots

Личные dotfiles и установщик для Arch Linux: **end-4 / illogical-impulse** (Hyprland + Quickshell), **fish**, **Neovim presets**, темы Serpantinum, MangoWC и универсальный `arch_multitool.sh`.

> **Авторство end-4:** профиль `end4/` — это моя персональная конфигурация/надстройки поверх [**end-4/dots-hyprland** (illogical-impulse)](https://github.com/end-4/dots-hyprland). Оригинальный проект, базовая shell/архитектура и заслуга за dots-hyprland принадлежат [end-4](https://github.com/end-4).

Репозиторий самодостаточный: конфиги можно применить вручную или через мультитул. Скрипт умеет брать конфиги из локальной папки репозитория или скачать их из GitHub.

- **Repo:** https://github.com/stylishlasher/stylish-dots/
- **GitHub Pages:** https://stylishlasher.github.io/stylish-dots/
- **Bio:**
https://lislash.vercel.app/
---

## Содержание

- [Что внутри](#что-внутри)
- [Быстрый старт](#быстрый-старт)
- [Профили dotfiles](#профили-dotfiles)
- [Neovim presets](#neovim-presets)
- [Структура репозитория](#структура-репозитория)
- [Куда применяются конфиги](#куда-применяются-конфиги)
- [end-4 / illogical-impulse](#end-4--illogical-impulse)
- [MangoWC](#mangowc)
- [Кастомные фетчи](#кастомные-фетчи)
- [GitHub Pages](#github-pages)
- [Благодарности](#благодарности)
- [Лицензия](#лицензия)

---

## Что внутри

- **`config/end4/`** — мой текущий конфиг для end-4/dots-hyprland (illogical-impulse): Hyprland custom overrides, патченный `hyprland/keybinds.lua`, Quickshell `illogical-impulse/config.json`, cursor/GTK/env.
- **`config/fish/`** — актуальный конфиг fish.
- **`config/nvim/`** — активный Neovim конфиг (LazyVim, `lazyvim-stylish`).
- **`config/nvim-presets/`** — выбор пресета Neovim:
  - `lazyvim-stylish/` — новый проработанный LazyVim;
  - `super-easy-casual/` — старый лёгкий конфиг из прошлого коммита.
- **`config/themes/`** — JSON-пресеты Serpantinum/темы.
- **`config/fetches/unstable/`** — кастомные C-фетчи, помечены как **UNSTABLE/BETA, kind of abandoned**.
- **`config/mango/`, `config/waybar/`, `config/foot/`, `config/fuzzel/`, `config/mako/`, `config/matugen/`, `config/bin/`** — MangoWC/Wayland dotfiles и утилиты.
- **`docs/`** — кастомный сайт GitHub Pages в стиле Material You.
- **`arch_multitool.sh`** — интерактивный установщик/мультитул.

---

## Быстрый старт

### Arch Linux (основной)

Одной командой (без клонирования репо):

```bash
curl -fsSL https://raw.githubusercontent.com/stylishlasher/stylish-dots/main/arch_multitool.sh | bash
```

Через bootstrap-установщик:

```bash
curl -fsSL https://raw.githubusercontent.com/stylishlasher/stylish-dots/main/install/install.sh | bash
```

Или вручную:

```bash
git clone https://github.com/stylishlasher/stylish-dots.git
cd stylish-dots
bash arch_multitool.sh
```

### Debian / Ubuntu-based (адаптированная версия)

Одной командой (без клонирования репо):

```bash
curl -fsSL https://raw.githubusercontent.com/stylishlasher/stylish-dots/main/arch_multitool_debian.sh | bash
```

Через bootstrap-установщик:

```bash
curl -fsSL https://raw.githubusercontent.com/stylishlasher/stylish-dots/main/install/install_debian.sh | bash
```

Или вручную:

```bash
git clone https://github.com/stylishlasher/stylish-dots.git
cd stylish-dots
bash arch_multitool_debian.sh
```

> Arch-версия рассчитана на Arch/pacman. Debian-версия — best-effort для Debian/Ubuntu-based (`apt` вместо pacman/AUR): AUR/Serpantinum/end-4 могут требовать ручной установки зависимостей.

---

## Профили dotfiles

Мультитул (пункт **4**) и полная установка поддерживают выбор профиля:

| Профиль | Что делает |
|---|---|
| **end-4 / illogical-impulse** | Применяет мой текущий конфиг из `end4/` поверх установленного dots-hyprland. |
| **serpantinum** | Запускает внешний установщик Serpantinum, патчит раскладку Hyprland, применяет темы из `themes/`. |
| **stylish-dots** | Применяет мои дотсы из этого репо: fish, выбранный Neovim preset, опционально end-4/MangoWC. |

В полном сценарии профиль выбирается до установки пакетов; после установки fish/nvim/end-4 применяются в соответствии с выбором.

---

## Neovim presets

При установке Neovim (пункт **6**) или в профиле `stylish-dots` можно выбрать пресет:

| Preset | Описание |
|---|---|
| **lazyvim-stylish** | Новый проработанный LazyVim: Snacks UI, noice, neo-tree, treesitter extras, тема `dots` (Material You из quickshell), RU langmap, шпаргалка. |
| **super-easy-casual** | Старый простой конфиг из прошлого коммита, один `init.lua`. |

Шпаргалка: `nvim/cheatsheet.md`, в Neovim — `F1`, `<leader>H` или `:Cheat`.

---

## Структура репозитория

```text
stylish-dots/
├── arch_multitool.sh        # основной мультитул
├── install/
│   │   └── install.sh           # bootstrap (curl | bash)
├── config/                  # все конфиги/ресурсы (чтобы не захламлять корень)
│   ├── end4/                # мой текущий end-4 / illogical-impulse конфиг
│   │   ├── hypr/
│   │   ├── illogical-impulse/
│   │   ├── gtk-3.0/ gtk-4.0/
│   │   ├── environment.d/
│   │   └── install.sh
│   ├── fish/                # активный fish конфиг
│   ├── nvim/                # активный LazyVim конфиг
│   ├── nvim-presets/
│   │   ├── lazyvim-stylish/
│   │   └── super-easy-casual/
│   ├── themes/              # JSON-пресеты/темы Serpantinum
│   ├── fetches/
│   │   └── unstable/        # UNSTABLE/BETA C-фетчи (kind of abandoned)
│   ├── mango/               # MangoWC конфиги
│   ├── waybar/ foot/ fuzzel/ mako/ matugen/ bin/
├── docs/                    # GitHub Pages (Material You)
│   └── install.txt          # команда установки Serpantinum (опционально)
├── README.md
└── LICENSE.md
```

---

## Куда применяются конфиги

| Что | Куда |
|---|---|
| end-4 / illogical-impulse | `~/.config/hypr/custom/`, `~/.config/hypr/hyprland/keybinds.lua`, `~/.config/illogical-impulse/config.json`, `~/.config/environment.d/`, GTK/cursor files |
| fish | `~/.config/fish/` |
| Neovim preset | `~/.config/nvim/` |
| MangoWC | `~/.config/mango/`, `~/.config/waybar/`, `~/.config/foot/`, `~/.config/fuzzel/`, `~/.config/mako/`, `~/.config/matugen/`, `~/.local/bin/mango-settings` |
| Темы Serpantinum | `~/.local/state/serpantinum/presets/` |
| Приветствие терминала | `~/.config/arch_multitool/greeting.fish` |

> Перед заменой существующих конфигов мультитул/скрипты делают бэкап (`*.bak.<timestamp>` или backup dir).

> **Важно:** API-ключи не хранятся в репозитории. AI-ключи для illogical-impulse добавляются через UI и сохраняются в keyring.

---

## end-4 / illogical-impulse

**Credits:** [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) by [end-4](https://github.com/end-4) — оригинальный проект. `config/end4/` в этом репозитории содержит **мои** пользовательские оверрайды/конфиг поверх него, а не замену оригинала.

Мой действующий конфиг лежит в `config/end4/` и ставится отдельно:

```bash
cd stylish-dots
bash config/end4/install.sh
```

Или через мультитул: пункт **17** или профиль **end-4 / stylish-dots**.

Что включает:
- `hypr/custom/*.lua` — monitor/layout/env/rules/execs;
- `hypr/hyprland/keybinds.lua` — патч Print/скриншотов;
- `illogical-impulse/config.json` — shell/AI prefs (без API ключей);
- Bibata cursor, GTK settings, `environment.d/10-cursor.conf`.

> Перед применением должен быть установлен сам [dots-hyprland / illogical-impulse](https://github.com/end-4/dots-hyprland).

---

## MangoWC

MangoWC dotfiles остались в репо и ставятся через пункт **16** мультитула или `mango/install.sh`.

```bash
cd stylish-dots
bash config/mango/install.sh
```

---

## Кастомные фетчи

C-фетчи перенесены в `config/fetches/unstable/`: `keyfetch`, `treefetch`, `tomatofetch`, `stoolfetch`, `skeletonfetch`.

Статус: **UNSTABLE/BETA, kind of abandoned**. В мультитуле они не предлагаются как обычный дефолт — их нужно явно включить в выборе приветствия терминала.

## Fish/CLI утилиты (полезности)

В `config/bin/` и `config/fish/functions/` добавлены утилиты:

- `fakefetch` — фейковый fastfetch/neofetch для дистро: `fakefetch -l arch -s stylish|original|mini|ultra|neon|box`
- `styletext` — ASCII-арт текст: `styletext "hello"`, `styletext --random-font "hello"`, `styletext -F border "hi"` (figlet/toilet если есть)
- `converttool` — конвертер файлов (ffmpeg/imagemagick/pandoc при наличии): `converttool in.png out.webp`, `converttool *.wav .mp3 --batch`
- `clipkeep` — история буфера (wl-copy/wl-paste/xclip): `clipkeep save`, `clipkeep list`, `clipkeep copy 1`
- `quicknote` — быстрые заметки в `~/Notes/quicknotes.md`: `quicknote "текст"`, `quicknote -l`, `quicknote -s слово`
- Fish функции: `mkcd`, `extract`, `servehere`, `fire`, `clipkeep`, `quicknote`
- Доп. aliases в fish: `.. ... .... gs ga gc gp gl gdiff myip ports ll lt path please`

## HackerLARP (консольный прикол)

`config/bin/hackerlarp` — настраиваемый rofl/larp Hollywood-симулятор в терминале. **Никакого реального взлома**: только фейковые анимации/вывод.

- Модули: `banner`, `scan`, `bruteforce`, `decrypt`, `download`, `exploit`, `exfil`, `matrix`, `wifi`, `trace`, `sqlinject`, `ddos`, `bitcoin`, `camera`, `git`, `docker`, `phishing`, `wipe`, `compile`, `satellite`, `firewall`, `ssh_tunnel`
- Настройка: `~/.config/hackerlarp/config.json` (скорость, тема, модули, цели, wordlist, файлы, loop/duration/seed, `show_disclaimer`)
- Флаги: `--no-disclaimer` скрывает сообщения о симуляции/фейке, `--disclaimer` включает обратно
- Пример конфига: `config/bin/hackerlarp.config.example.json`

Запуск локально:

```bash
python3 config/bin/hackerlarp --write-config
python3 config/bin/hackerlarp --theme amber --speed 1.2 --modules banner,scan,bruteforce,wifi,bitcoin,matrix
python3 config/bin/hackerlarp --no-disclaimer --once
```

Установка через мультитул: **Консольные приколы → LARP / кино-хакер (hackerlarp)**.

---

## Рекомендации

- **Пак обоев:** [Wallpaper Pack 25 (TMS Wallpapers) — 4K 3840x2160](https://forums.tms.sx/threads/wallpaper-pack-25-tms-wallpapers-4k-3840x2160-1-1000.40932/)
- **Firefox расширения:**
  - [Dark Reader](https://addons.mozilla.org/ru/firefox/addon/darkreader/)
  - [uBlock Origin](https://addons.mozilla.org/ru/firefox/addon/ublock-origin/)
  - [DuckDuckGo Privacy Essentials](https://addons.mozilla.org/ru/firefox/addon/duckduckgo-for-firefox/)
  - [Privacy Badger](https://addons.mozilla.org/ru/firefox/addon/privacy-badger17/)
  - [SponsorBlock](https://addons.mozilla.org/ru/firefox/addon/sponsorblock/)

---

## GitHub Pages

Сайт лежит в `docs/` и деплоится GitHub Pages из ветки `main`, папка `/docs`.

Включение:
1. Repo **Settings → Pages**
2. **Build and deployment → Source: Deploy from a branch**
3. **Branch: `main` / Folder: `/docs`**

Сайт: https://stylishlasher.github.io/stylish-dots/

---

## Благодарности

- **[end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)** by [end-4](https://github.com/end-4) — оригинальный проект illogical-impulse / dots-hyprland, базовая shell-архитектура и огромная работа над экосистемой. Мой `config/end4/` — это пользовательские оверрайды поверх него.
- **[Serpantinum](https://github.com/ilyamiro/serpantinum)** by [Illia Miroshnichenko (@ilyamiro)](https://github.com/ilyamiro) — Wayland-окружение/пресеты/темы, которые использует профиль `serpantinum` и часть theme/preset flow в мультитуле. Сайт: https://serpantinum.dev.

---

## Лицензия

Этот репозиторий распространяется под лицензией **GNU AGPL-3.0** (см. [LICENSE.md](LICENSE.md)).

Я ба