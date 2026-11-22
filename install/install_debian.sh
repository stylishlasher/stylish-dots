#!/usr/bin/env bash
# ==============================================================================
# LINUX MULTITOOL (Debian) — установщик (bootstrap)
# ==============================================================================
# Скачивает актуальный arch_multitool_debian.sh из репозитория и запускает его.
# Все аргументы пробрасываются в мультитул (например, -f или -a).
#
# Быстрый запуск:
#   curl -fsSL https://raw.githubusercontent.com/stylishlasher/stylish-dots/main/install/install.sh | bash
#
# Полная установка без меню:
#   curl -fsSL https://raw.githubusercontent.com/stylishlasher/stylish-dots/main/install/install.sh | bash -s -- -f
# ==============================================================================

set -euo pipefail

# ------------------------------- Настройки -----------------------------------
REPO_SLUG="${REPO_SLUG:-stylishlasher/stylish-dots}"
REPO_BRANCH="${REPO_BRANCH:-main}"
RAW_BASE="https://raw.githubusercontent.com/${REPO_SLUG}/${REPO_BRANCH}"

# Куда сохранить мультитул (чтобы можно было перезапускать без интернета)
INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/arch-multitool"
MULTITOOL="$INSTALL_DIR/arch_multitool_debian.sh"

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
command -v apt-get >/dev/null 2>&1 || die "apt-get не найден — нужна Debian/Ubuntu-based система."

banner

# Ищем локальную копию мультитула (если запущено из клонированного репозитория)
LOCAL_MULTITOOL=""
SELF="${BASH_SOURCE[0]:-}"
if [[ -n "$SELF" && -f "$SELF" ]]; then
    self_dir="$(cd -- "$(dirname -- "$(realpath "$SELF")")" && pwd)"
    for cand in "$self_dir/arch_multitool_debian.sh" "$self_dir/../arch_multitool_debian.sh"; do
        if [[ -f "$cand" ]]; then
            LOCAL_MULTITOOL="$cand"
            break
        fi
    done
fi

mkdir -p "$INSTALL_DIR"

# ------------------------------- Получение файла -----------------------------
if [[ -n "$LOCAL_MULTITOOL" ]]; then
    say "Использую локальную копию: $LOCAL_MULTITOOL"
    cp -f "$LOCAL_MULTITOOL" "$MULTITOOL"
else
    if ! command -v curl >/dev/null 2>&1; then
        say "Устанавливаю curl..."
        sudo pacman -S --needed --noconfirm curl || die "Не удалось установить curl."
    fi
    say "Скачиваю Linux Multitool (Debian) из ${B}${REPO_SLUG}${N}${C} (ветка ${REPO_BRANCH})..."
    if ! curl -fsSL --connect-timeout 20 --retry 3 "${RAW_BASE}/arch_multitool_debian.sh" -o "$MULTITOOL"; then
        die "Не удалось скачать arch_multitool_debian.sh (проверьте интернет и имя репозитория)."
    fi
fi

chmod +x "$MULTITOOL"
ok "Мультитул сохранён: $MULTITOOL"
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
