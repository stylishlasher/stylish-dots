# stylish-dots

🇷🇺 Русский · 🇬🇧 [English](README.en.md) · 🇷🇴 [Română](README.ro.md)

Личные dotfiles и установщик для Arch Linux: **end-4 / illogical-impulse** (Hyprland + Quickshell), **fish**, **Neovim presets**, темы Serpantinum, MangoWC и универсальный `arch_multitool.sh`.

> **Авторство end-4:** профиль `end4/` — это моя персональная конфигурация/надстройки поверх [**end-4/dots-hyprland** (illogical-impulse)](https://github.com/end-4/dots-hyprland). Оригинальный проект, базовая shell/архитектура и заслуга за dots-hyprland принадлежат [end-4](https://github.com/end-4).

Репозиторий самодостаточный: конфиги можно применить вручную или через мультитул. Скрипт умеет брать конфиги из локальной папки репозитория или скачать их из GitHub.

- **Repo:** https://github.com/stylishlasher/stylish-dots/
- **GitHub Pages:** https://stylishlasher.github.io/stylish-dots/
- **Bio (Там мой тгк и личка и прочее роблокс там):**
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
- **`config/fetches/stylish-fetches/`** — Rust-перепись бывших нестабильных C-фетчей (3D fetches, ручной запуск по команде).
- **`config/fastfetch/presets/`** — пресеты fastfetch: `default`, `mine`, `micro`, `stylish`, `universal`.
- **`config/mango/`, `config/waybar/`, `config/foot/`, `config/fuzzel/`, `config/mako/`, `config/matugen/`, `config/bin/`** — MangoWC/Wayland dotfiles и утилиты.
- **`docs/`** — кастомный сайт GitHub Pages в стиле Material You.
- **`arch_multitool.sh`** — GUI/меню-мультитул (Arch), **`arch_multitool_debian.sh`** — Debian/Ubuntu адаптация.
- **`modules/`** — модули действий: мультитул содержит UI, а установка/применение конфигов выполняется модулями (докачиваются по необходимости).

---

## Быстрый старт

### Arch Linux (основной)

Одной командой (без клонирования репо):

```bash
curl -fsSL https://raw.githubusercontent.com/stylishlasher/stylish-dots/main/install/install.sh | bash
```

Из клонированного репозитория:

```bash
git clone https://github.com/stylishlasher/stylish-dots.git
cd stylish-dots
bash install/install.sh
```

### Debian / Ubuntu-based (адаптированная версия)

Одной командой (без клонирования репо):

```bash
curl -fsSL https://raw.githubusercontent.com/stylishlasher/stylish-dots/main/install/install_debian.sh | bash
```

Из клонированного репозитория:

```bash
git clone https://github.com/stylishlasher/stylish-dots.git
cd stylish-dots
bash install/install_debian.sh
```

> Оба мультитула — GUI/меню-оболочки: логика в `modules/`. Bootstrap-установщики (`install/install.sh`, `install/install_debian.sh`) кладут лаунчеры, `modules/` и `config/` в `~/.local/share/arch-multitool`, поэтому после первого запуска всё работает офлайн; `bash install/install.sh --refresh` обновляет кэш (для Debian — `install_debian.sh --refresh`). Прямой запуск лаунчеров отключён: они только печатают подсказку и требуют bootstrap.
> Arch-версия рассчитана на pacman/AUR, Debian-версия — best-effort для apt/dpkg.
>
> Манифест набора (`bundle.sha256`) подписан RSA-ключом: публичный вшит в оба `install/*.sh`, приватного в репозитории нет. Проверяются SHA-256 каждого файла, права доступа и символьные ссылки — подмена файлов вместе с манифестом не пройдёт. После изменений в `modules/` или `config/` переподписывай манифест: `bash scripts/sign-bundle.sh` (приватный ключ — `STYLISH_SIGNING_KEY` или `~/.local/share/stylish-dots/signing.key`). Неподписанным остаётся только сам `install/*.sh`, который грузится по HTTPS.
>
> это уже паранойя, но комфорт юзера - главное

---

## Профили dotfiles

**Полная интерактивная установка** (пункт 1) — мастер из четырёх шагов: профиль dotfiles → выбор ПО → конфиги и пресеты → сводка с подтверждением. Всё по желанию: ничего не ставится без галочки, профиль можно пропустить. Галочка «Тема SDDM для профиля» докачивает только тему выбранных дотсов; если профиль пропущен, тему можно выбрать отдельным вопросом.

| Профиль | Что делает |
|---|---|
| **Caelestia** | `caelestia-cli` из AUR + `caelestia install` (только Arch; компоненты выбирает апстрим). |
| **end-4 / illogical-impulse** | Применяет мой текущий конфиг из `end4/` поверх установленного dots-hyprland. |
| **serpantinum** | Внешний установщик Serpantinum (через его installer), темы/пресеты можно применять из `config/themes/`. |
| **stylish-dots** | Применяет мои дотсы: fish, Neovim preset, fastfetch preset, Rust 3D fetches. |

Пункты 6–11 меню «Установка ПО» отдельно ставят SDDM, Caelestia, курсоры Bibata Modern Classic / Modern Ice (GTK, X11, Qt, Hyprland), настраивают мониторы на максимум герц через `hyprctl`, `wlr-randr` или `xrandr`, а также кладут четыре темы SDDM (по одной на профиль: `caelestia`, `end4`, `stylish`, `serpantinum`) в `~/.local/share/sddm/themes` — без root. Пункт 11 меняет аватар или фон любой темы: `config/sddm-themes/set-image.sh <тема> <avatar|background> <путь>`. Для экрана входа темы надо скопировать вместе с `_assets` в `/usr/share/sddm/themes` и указать `Current=` в `/etc/sddm.conf.d/`; посмотреть можно через `sddm-greeter-qt6 --test-mode --theme ~/.local/share/sddm/themes/stylish`. Пункт 9 главного меню «Очистить кэш скрипта» удаляет `~/.local/share/arch-multitool` после подтверждения; вернуть кэш можно `bash install/install.sh` (для Debian — `install_debian.sh`). На Debian Caelestia — best-effort, официально она только под Arch.

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
├── arch_multitool.sh        # Arch GUI-мультитул (загружает modules/)
├── arch_multitool_debian.sh # Debian/Ubuntu GUI-мультитул
├── modules/                 # модули действий (докачиваются при необходимости)
│   ├── lib/                 # common/platform/menu/loader
│   └── actions/             # fish, neovim, fetches, dotfiles, software, interactive...
├── install/
│   ├── install.sh           # bootstrap Arch (curl | bash)
│   └── install_debian.sh    # bootstrap Debian/Ubuntu
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
│   │   ├── unstable/        # старые C-исходники (legacy, не используются по умолчанию)
│   │   └── stylish-fetches/ # Rust 3D fetches (keyfetch/treefetch/tomatofetch/stoolfetch/skeletonfetch)
│   ├── fastfetch/presets/   # default/mine/micro/stylish/universal
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
| Stylish 3D fetches (Rust) | `~/.local/bin/{keyfetch,treefetch,tomatofetch,stoolfetch,skeletonfetch}` |
| Консольные приколы | `~/.local/bin/{csorting,hackerlarp}`, `~/.config/fish/functions/csorting.fish` |

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

Rust 3D fetches лежат в `config/fetches/stylish-fetches/` и запускаются вручную: `keyfetch`, `treefetch`, `tomatofetch`, `stoolfetch`, `skeletonfetch`. Режимы вращения: `--rotate horizontal|vertical|random`.

Старые C-исходники сохранены в `config/fetches/unstable/` как legacy/abandoned.

## Fastfetch пресеты

В `config/fastfetch/presets/` есть пресеты: `default`, `mine`, `micro`, `stylish`, `universal`. Мультитул умеет установить выбранный пресет в `~/.config/fastfetch/config.jsonc` (с бэкапом старого).

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

## csorting (фоновая сортировка)

`config/bin/csorting` — лёгкий визуализатор сортировок без зависимостей (только stdlib Python). Точки собираются в круг по градиенту (по мере сортировки превращаются в аккуратную спираль), полоски растут вертикально от маленькой к большой. Каждая перестановка/сравнение показывается отдельным кадром; когда массив отсортирован — рандомизация и следующий алгоритм.

- Виды: `--circle` (точки) и `--line` (полоски, по умолчанию)
- Алгоритмы: `bubble`, `cocktail`, `gnome`, `insertion`, `selection`, `shell`, `comb`, `oddeven`, `quick`, `heap`, `merge`
- `--algorithm all` (по умолчанию) перебирает их по очереди; `--algorithm shell` или позиционный аргумент `csorting --circle shell` закрепляет один
- Выход: `Ctrl+C`, `Ctrl+D`, `q` или `Esc`
- Проверка алгоритмов: `python3 config/bin/csorting --self-test`

```bash
csorting --circle
csorting --line --algorithm gnome --delay 0.02
csorting --circle shell
```

Установка через мультитул: **Консольные приколы → csorting** (копируется в `~/.local/bin`, fish-функция — в `~/.config/fish/functions`).

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
