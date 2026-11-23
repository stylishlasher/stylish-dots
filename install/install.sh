#!/usr/bin/env bash
# ==============================================================================
# ARCH MULTITOOL — установщик (bootstrap)
# ==============================================================================
# Ставит мультитул, модули и конфиги в ~/.local/share/arch-multitool и запускает.
# После этого мультитул работает без интернета. --refresh обновляет кэш.
#
# Быстрый запуск:
#   curl -fsSL https://raw.githubusercontent.com/stylishlasher/stylish-dots/main/install/install.sh | bash
#
# Полная установка без меню:
#   curl -fsSL https://raw.githubusercontent.com/stylishlasher/stylish-dots/main/install/install.sh | bash -s -- -f
#
# Обновить кэш модулей/конфигов:
#   bash install/install.sh --refresh
# ==============================================================================

set -euo pipefail

# ------------------------------- Настройки -----------------------------------
REPO_SLUG="${REPO_SLUG:-stylishlasher/stylish-dots}"
REPO_BRANCH="${REPO_BRANCH:-main}"
RAW_BASE="https://raw.githubusercontent.com/${REPO_SLUG}/${REPO_BRANCH}"
CONFIG_TARBALL="https://codeload.github.com/${REPO_SLUG}/tar.gz/refs/heads/${REPO_BRANCH}"

# Куда положить мультитул, модули и конфиги (перезапуск без интернета)
INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/arch-multitool"
MULTITOOL="$INSTALL_DIR/arch_multitool.sh"

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

# Ищем локальную копию мультитула (если запущено из клонированного репозитория)
LOCAL_DIR=""
SELF="${BASH_SOURCE[0]:-}"
if [[ -n "$SELF" && -f "$SELF" ]]; then
    self_dir="$(cd -- "$(dirname -- "$(realpath "$SELF")")" && pwd)"
    for cand in "$self_dir" "$self_dir/.."; do
        if [[ -f "$cand/arch_multitool.sh" ]]; then
            LOCAL_DIR="$(cd -- "$cand" && pwd)"
            break
        fi
    done
fi

mkdir -p "$INSTALL_DIR"

ensure_curl() {
    command -v curl >/dev/null 2>&1 && return 0
    say "Устанавливаю curl..."
    sudo pacman -S --needed --noconfirm curl || die "Не удалось установить curl."
}

# Кладёт modules/ и config/ в кэш: из локального репо или tarball с GitHub.
cache_repo() {
    local tmp
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/stylish-bootstrap.XXXXXX")" || die "Не удалось создать временный каталог."
    if [[ -n "$LOCAL_DIR" && -d "$LOCAL_DIR/modules" && -d "$LOCAL_DIR/config" ]]; then
        say "Копирую modules/ и config/ из $LOCAL_DIR"
        cp -a "$LOCAL_DIR/modules" "$tmp/modules" || die "Не удалось скопировать modules/."
        cp -a "$LOCAL_DIR/config" "$tmp/config" || die "Не удалось скопировать config/."
    else
        ensure_curl
        say "Скачиваю модули и конфиги из ${B}${REPO_SLUG}${N}${C} (ветка ${REPO_BRANCH})..."
        curl -fsSL --connect-timeout 20 --retry 3 "$CONFIG_TARBALL" -o "$tmp/repo.tar.gz" || die "Не удалось скачать репозиторий."
        tar -xzf "$tmp/repo.tar.gz" -C "$tmp" --strip-components=1 modules config || die "Не удалось распаковать репозиторий."
    fi
    rm -rf "$INSTALL_DIR/modules.new" "$INSTALL_DIR/config.new"
    mv "$tmp/modules" "$INSTALL_DIR/modules.new" || die "Не удалось обновить кэш modules/."
    mv "$tmp/config" "$INSTALL_DIR/config.new" || die "Не удалось обновить кэш config/."
    rm -rf "$tmp"
    rm -rf "$INSTALL_DIR/modules" "$INSTALL_DIR/config"
    mv "$INSTALL_DIR/modules.new" "$INSTALL_DIR/modules"
    mv "$INSTALL_DIR/config.new" "$INSTALL_DIR/config"
}

# --------------------------- Получение лаунчера ------------------------------
if [[ -n "$LOCAL_DIR" ]]; then
    say "Использую локальную копию: $LOCAL_DIR/arch_multitool.sh"
    cp -f "$LOCAL_DIR/arch_multitool.sh" "$MULTITOOL"
else
    ensure_curl
    say "Скачиваю Arch Multitool из ${B}${REPO_SLUG}${N}${C} (ветка ${REPO_BRANCH})..."
    curl -fsSL --connect-timeout 20 --retry 3 "${RAW_BASE}/arch_multitool.sh" -o "$MULTITOOL" || die "Не удалось скачать arch_multitool.sh."
fi
chmod +x "$MULTITOOL"

# ------------------------------- Кэш модулей --------------------------------
if [[ "$REFRESH" == "1" || ! -f "$INSTALL_DIR/modules/lib/multitool.sh" || ! -d "$INSTALL_DIR/config/fastfetch" ]]; then
    cache_repo
else
    say "Кэш modules/ и config/ уже есть — работаю офлайн (--refresh для обновления)."
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
