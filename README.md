# stylish-dots

Личные dotfiles и установщик для Arch Linux: **end-4 / illogical-impulse** (Hyprland + Quickshell), **fish**, **Neovim presets**, темы Serpantinum, MangoWC и универсальный `arch_multitool.sh`.

> **Авторство end-4:** профиль `end4/` — это моя персональная конфигурация/надстройки поверх [**end-4/dots-hyprland** (illogical-impulse)](https://github.com/end-4/dots-hyprland). Оригинальный проект, базовая shell/архитектура и заслуга за dots-hyprland принадлежат [end-4](https://github.com/end-4).

Репозиторий самодостаточный: конфиги можно применить вручную или через мультитул. Скрипт умеет брать конфиги из локальной папки репозитория или скачать их из GitHub.

- **Repo:** https://github.com/stylishlasher/stylish-dots
- **GitHub Pages:** https://stylishlasher.github.io/stylish-dots/

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
- [Лицензия](#лицензия)

---

## Что внутри

- **`end4/`** — мой текущий конфиг для end-4/dots-hyprland (illogical-impulse): Hyprland custom overrides, патченный `hyprland/keybinds.lua`, Quickshell `illogical-impulse/config.json`, cursor/GTK/env.
- **`fish/`** — актуальный конфиг fish.
- **`nvim/`** — активный Neovim конфиг (LazyVim, `lazyvim-stylish`).
- **`nvim-presets/`** — выбор пресета Neovim:
  - `lazyvim-stylish/` — новый проработанный LazyVim;
  - `super-easy-casual/` — старый лёгкий конфиг из прошлого коммита.
- **`themes/`** — JSON-пресеты Serpantinum/темы.
- **`fetches/unstable/`** — кастомные C-фетчи, помечены как **UNSTABLE/BETA, kind of abandoned**.
- **`mango/`, `waybar/`, `foot/`, `fuzzel/`, `mako/`, `matugen/`, `bin/`** — MangoWC/Wayland dotfiles и утилиты.
- **`docs/`** — кастомный сайт GitHub Pages в стиле Material You.
- **`arch_multitool.sh`** — интерактивный установщик/мультитул.

---

## Быстрый старт

### Мультитул (интерактивно)

```bash
git clone https://github.com/stylishlasher/stylish-dots.git
cd stylish-dots
bash arch_multitool.sh
```

### Bootstrap-установщик

```bash
curl -fsSL https://raw.githubusercontent.com/stylishlasher/stylish-dots/main/install/install.sh | bash
```

Полная установка без меню:

```bash
curl -fsSL https://raw.githubusercontent.com/stylishlasher/stylish-dots/main/install/install.sh | bash -s -- -f
```

Только аудит системы:

```bash
curl -fsSL https://raw.githubusercontent.com/stylishlasher/stylish-dots/main/install/install.sh | bash -s -- -a
```

> Требуется Arch Linux/производный дистрибутив с `pacman`. Запускать от обычного пользователя; `sudo` запрашивается по необходимости.

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
│   └── install.sh           # bootstrap (curl | bash)
├── end4/                    # мой текущий end-4 / illogical-impulse конфиг
│   ├── hypr/
│   ├── illogical-impulse/
│   ├── gtk-3.0/ gtk-4.0/
│   ├── environment.d/
│   └── install.sh
├── fish/                    # активный fish конфиг
├── nvim/                    # активный LazyVim конфиг
├── nvim-presets/
│   ├── lazyvim-stylish/     # новый LazyVim preset
│   └── super-easy-casual/   # старый конфиг из прошлого коммита
├── themes/                  # JSON-пресеты/темы Serpantinum
├── fetches/
│   └── unstable/            # UNSTABLE/BETA C-фетчи (kind of abandoned)
├── mango/                   # MangoWC конфиги
├── waybar/ foot/ fuzzel/ mako/ matugen/ bin/
├── docs/                    # GitHub Pages (Material You)
├── install.txt              # команда установки Serpantinum (опционально)
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

**Credits:** [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) by [end-4](https://github.com/end-4) — оригинальный проект. `end4/` в этом репозитории содержит **мои** пользовательские оверрайды/конфиг поверх него, а не замену оригинала.

Мой действующий конфиг лежит в `end4/` и ставится отдельно:

```bash
cd stylish-dots
bash end4/install.sh
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
bash mango/install.sh
```

---

## Кастомные фетчи

C-фетчи перенесены в `fetches/unstable/`: `keyfetch`, `treefetch`, `tomatofetch`, `stoolfetch`, `skeletonfetch`.

Статус: **UNSTABLE/BETA, kind of abandoned**. В мультитуле они не предлагаются как обычный дефолт — их нужно явно включить в выборе приветствия терминала.

---

## GitHub Pages

Сайт лежит в `docs/` и деплоится GitHub Pages из ветки `main`, папка `/docs`.

Включение:
1. Repo **Settings → Pages**
2. **Build and deployment → Source: Deploy from a branch**
3. **Branch: `main` / Folder: `/docs`**

Сайт: https://stylishlasher.github.io/stylish-dots/

---

## Лицензия

Этот репозиторий распространяется под лицензией **GNU AGPL-3.0** (см. [LICENSE.md](LICENSE.md)).
