# modules/

🇷🇺 Русский · 🇬🇧 [English](README.en.md) · 🇷🇴 [Română](README.ro.md)

Модульная система stylish-dots. Мультитулы (`arch_multitool.sh`, `arch_multitool_debian.sh`) отвечают за UI/меню, а действия вынесены в модули.

## Структура

- `lib/` — общие хелперы:
  - `common.sh` — логирование, sudo, resolve_configs, backup/normalize
  - `platform.sh` — определение платформы и pkg_install/pkg_update
  - `menu.sh` — menu_select/select_packages
  - `loader.sh` — докачка/подключение модулей, run_action
- `actions/` — действия:
  - `interactive.sh` — полная установка: мастер из 4 шагов
  - `software.sh` — меню ПО
  - `extras.sh` — SDDM, Caelestia, курсоры Bibata, мониторы, очистка кэша
  - `dotfiles.sh` — применение профилей/configs
  - `fish.sh`, `neovim.sh`, `fetches.sh`, `flatpak.sh`, `network.sh`, `system.sh`, `audit.sh`

## Как работает

При запуске мультитула он подгружает `lib/*`. Когда пользователь выбирает действие, `run_action` подключает нужный `actions/*.sh`. Если модуля нет локально (например, при `curl | bash`), loader скачивает его из `https://raw.githubusercontent.com/stylishlasher/stylish-dots/main/modules/...`.

## Расширение

Добавляй новый action в `modules/actions/<name>.sh`, экспортируй функцию `action_*`, зарегистрируй в `modules/lib/loader.sh` в `run_action`.
