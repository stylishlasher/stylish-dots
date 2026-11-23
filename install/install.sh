#!/usr/bin/env bash
# ==============================================================================
# ARCH MULTITOOL — установщик (bootstrap)
# ==============================================================================
# Ставит лаунчер, modules/ и config/ в ~/.local/share/arch-multitool и запускает.
# Загрузка динамическая: из git берутся только нужные пути (sparse + blob:none),
# git проверяет SHA объектов, всё содержимое дополнительно проходит bash -n.
# Замена лаунчера и кэша атомарная: при любой ошибке возвращается прежняя версия.
# Повторный запуск работает без сети. --refresh обновляет весь набор.
#
# Быстрый запуск:
#   curl -fsSL https://raw.githubusercontent.com/stylishlasher/stylish-dots/main/install/install.sh | bash
#
# Полная установка без меню:
#   curl -fsSL https://raw.githubusercontent.com/stylishlasher/stylish-dots/main/install/install.sh | bash -s -- -f
#
# Обновить лаунчер и кэш:
#   bash install/install.sh --refresh
# ==============================================================================

set -euo pipefail

# ------------------------------- Настройки -----------------------------------
REPO_SLUG="${REPO_SLUG:-stylishlasher/stylish-dots}"
REPO_BRANCH="${REPO_BRANCH:-main}"
REPO_URL="https://github.com/${REPO_SLUG}.git"

# Куда положить мультитул, модули и конфиги (перезапуск без интернета)
INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/arch-multitool"
MULTITOOL="$INSTALL_DIR/arch_multitool.sh"
LAUNCHER="${MULTITOOL##*/}"

# --------------------------------- Цвета -------------------------------------
if [[ -t 2 ]]; then
    C=$'\033[0;36m'; G=$'\033[0;32m'; Y=$'\033[1;33m'; R=$'\033[0;31m'; B=$'\033[1m'; N=$'\033[0m'
else
    C=''; G=''; Y=''; R=''; B=''; N=''
fi
say()  { printf '%s\n' "${C}$*${N}" >&2; }
ok()   { printf '%s\n' "${G}$*${N}" >&2; }
warn() { printf '%s\n' "${Y}$*${N}" >&2; }
die()  { printf '%s\n' "${R}$*${N}" >&2; exit 1; }

banner() {
    printf '%s' "${B}${C}" >&2
    cat >&2 <<'ASCII'
  ╔═══════════════════════════════════════════════╗
  ║            A R C H   M U L T I T O O L        ║
  ║      установка · настройка · обслуживание     ║
  ╚═══════════════════════════════════════════════╝
ASCII
    printf '%s' "${N}" >&2
    echo >&2
}

# --------------------------------- Проверки ----------------------------------
[[ "$(uname -s)" == "Linux" ]] || die "Скрипт предназначен для Linux."
command -v pacman >/dev/null 2>&1 || die "pacman не найден — нужен Arch Linux или производный дистрибутив."
command -v tar >/dev/null 2>&1 || die "tar не найден — нужен для распаковки модулей и конфигов."

banner

# --refresh не пробрасываем в мультитул
REFRESH=0
ARGS=()
for a in "$@"; do
    if [[ "$a" == "--refresh" ]]; then REFRESH=1; else ARGS+=("$a"); fi
done
if (( ${#ARGS[@]} )); then set -- "${ARGS[@]}"; else set --; fi

# Ищем локальную копию с лаунчером, modules/ и config/ (клонированный репозиторий)
LOCAL_DIR=""
SELF="${BASH_SOURCE[0]:-}"
if [[ -n "$SELF" && -f "$SELF" ]]; then
    self_dir="$(cd -- "$(dirname -- "$SELF")" && pwd -P)"
    for cand in "$self_dir" "$self_dir/.."; do
        if [[ -f "$cand/$LAUNCHER" && -d "$cand/modules" && -d "$cand/config" ]]; then
            LOCAL_DIR="$(cd -- "$cand" && pwd -P)"
            break
        fi
    done
fi

mkdir -p "$INSTALL_DIR"

ensure_git() {
    command -v git >/dev/null 2>&1 && return 0
    say "Устанавливаю git (он проверит целостность загружаемых файлов)..."
    sudo pacman -S --needed --noconfirm git || die "Не удалось установить git."
}

# Проверяем весь набор до попадания в кэш: лаунчер, модули и конфиги.
verify_bundle() {
    local dir="$1" f
    [[ -f "$dir/$LAUNCHER" ]] || return 1
    bash -n "$dir/$LAUNCHER" || return 1
    [[ -f "$dir/modules/lib/multitool.sh" && -f "$dir/modules/lib/i18n.sh" && -f "$dir/modules/lib/common.sh" ]] || return 1
    [[ -d "$dir/config/fastfetch" && -d "$dir/config/end4" ]] || return 1
    while IFS= read -r -d '' f; do bash -n "$f" || return 1; done < <(find "$dir/modules" -type f -name '*.sh' -print0 2>/dev/null)
}

# Меняем лаунчер + кэш целиком; при любой ошибке возвращаем прежнюю версию.
swap_bundle() {
    local src="$1" tmp had_old=0 item
    tmp="$(mktemp -d "$INSTALL_DIR/.old.XXXXXX")" || die "Не удалось создать каталог для отката."
    for item in "$LAUNCHER" modules config; do
        if [[ -e "$INSTALL_DIR/$item" ]]; then
            had_old=1
            mv "$INSTALL_DIR/$item" "$tmp/$item"
        fi
    done
    if ! cp -a "$src/$LAUNCHER" "$INSTALL_DIR/$LAUNCHER" \
        || ! cp -a "$src/modules" "$INSTALL_DIR/modules" \
        || ! cp -a "$src/config" "$INSTALL_DIR/config" \
        || ! verify_bundle "$INSTALL_DIR"; then
        rm -rf "$INSTALL_DIR/$LAUNCHER" "$INSTALL_DIR/modules" "$INSTALL_DIR/config"
        if (( had_old )); then
            for item in "$LAUNCHER" modules config; do
                [[ -e "$tmp/$item" ]] && mv "$tmp/$item" "$INSTALL_DIR/$item"
            done
        fi
        rm -rf "$tmp"
        die "Не удалось обновить кэш — прежняя версия восстановлена."
    fi
    chmod +x "$MULTITOOL"
    rm -rf "$tmp"
}

# Динамическая загрузка: только лаунчер, modules/ и config/, ничего лишнего.
fetch_bundle() {
    local tmp
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/stylish-bootstrap.XXXXXX")" || die "Не удалось создать временный каталог."
    if [[ -n "$LOCAL_DIR" ]]; then
        say "Копирую $LAUNCHER, modules/ и config/ из $LOCAL_DIR"
        # tar с исключениями: в кэш не попадают target/, __pycache__ и прочие артефакты сборки
        tar -C "$LOCAL_DIR" -cf - --exclude='*/target' --exclude='*__pycache__' "$LAUNCHER" modules config | tar -xf - -C "$tmp" \
            || die "Не удалось скопировать файлы из локальной копии."
    else
        ensure_git
        say "Скачиваю только нужные пути ${B}${REPO_SLUG}${N}${C} (ветка ${REPO_BRANCH}); git проверяет SHA объектов..."
        git clone --depth 1 --filter=blob:none --sparse --branch "$REPO_BRANCH" "$REPO_URL" "$tmp/repo" \
            || die "Не удалось скачать репозиторий."
        git -C "$tmp/repo" sparse-checkout set modules config || die "Не удалось выбрать нужные пути."
        say "Коммит: $(git -C "$tmp/repo" rev-parse --short HEAD)"
        cp "$tmp/repo/$LAUNCHER" "$tmp/$LAUNCHER" || die "В репозитории нет $LAUNCHER."
        mv "$tmp/repo/modules" "$tmp/modules" || die "В репозитории нет modules/."
        mv "$tmp/repo/config" "$tmp/config" || die "В репозитории нет config/."
    fi
    verify_bundle "$tmp" || die "Загруженные файлы не прошли проверку целостности."
    swap_bundle "$tmp"
    rm -rf "$tmp"
}

# -------------------------- Лаунчер + кэш модулей -----------------------------
if [[ "$REFRESH" == "1" || ! -f "$MULTITOOL" || ! -f "$INSTALL_DIR/modules/lib/multitool.sh" || ! -d "$INSTALL_DIR/config/fastfetch" ]]; then
    fetch_bundle
else
    say "Лаунчер и кэш готовы — работаю офлайн (--refresh для обновления)."
fi

ok "Мультитул готов: $MULTITOOL"
ok "Модули: $INSTALL_DIR/modules · конфиги: $INSTALL_DIR/config"
echo >&2

# ---------------------------------- Запуск -----------------------------------
# Мультитул интерактивный, поэтому при запуске через "curl | bash" подсовываем ему TTY.
if [[ -t 0 ]]; then
    bash "$MULTITOOL" "$@"
elif { : < /dev/tty; } 2>/dev/null; then
    bash "$MULTITOOL" "$@" < /dev/tty
else
    warn "Интерактивный ввод недоступен — запускаю в текущем режиме."
    bash "$MULTITOOL" "$@"
fi
