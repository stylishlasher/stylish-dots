#!/usr/bin/env bash
# ==============================================================================
# ARCH MULTITOOL v4 — GUI-only launcher; actions live in modules/
# ==============================================================================
# -h help | -a audit | -f full auto install
# Modules are loaded from ./modules or downloaded from GitHub on demand.
# ==============================================================================

set -uo pipefail

REPO_SLUG="stylishlasher/stylish-dots"
REPO_BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/${REPO_SLUG}/${REPO_BRANCH}"
MODULES_RAW_BASE="${RAW_BASE}/modules"
CONFIG_TARBALL="https://codeload.github.com/${REPO_SLUG}/tar.gz/refs/heads/${REPO_BRANCH}"
export REPO_SLUG REPO_BRANCH RAW_BASE MODULES_RAW_BASE CONFIG_TARBALL
LOG_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/arch_multitool.log"
WORK_DIR=""

# Resolve script dir (works for file execution; curl|bash uses temp)
if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" != "bash" && -f "${BASH_SOURCE[0]}" ]]; then
    SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
else
    SCRIPT_DIR="$(pwd)"
fi
MODULES_DIR="$SCRIPT_DIR/modules"

mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

# Minimal bootstrap logging/colors before modules load
if [[ -t 1 ]]; then RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; CYAN=$'\033[0;36m'; BOLD=$'\033[1m'; NC=$'\033[0m'; else RED='';GREEN='';YELLOW='';CYAN='';BOLD='';NC=''; fi
info(){ echo -e "${CYAN}$*${NC}"; }
warn(){ echo -e "${YELLOW}$*${NC}"; }
err(){ echo -e "${RED}[✗] $*${NC}" >&2; }
ok(){ echo -e "${GREEN}[✓] $*${NC}"; }
has(){ command -v "$1" >/dev/null 2>&1; }

ensure_work_dir(){ [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]] || WORK_DIR="$(mktemp -d /tmp/stylish-dots.XXXXXX)"; }
cleanup(){ [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]] && rm -rf "$WORK_DIR"; }
trap cleanup EXIT INT TERM

bootstrap_module() {
    local rel="$1" dest="$MODULES_DIR/$rel"
    [[ -f "$dest" ]] && return 0
    mkdir -p "$(dirname "$dest")"
    if has curl; then
        curl -fsSL "$MODULES_RAW_BASE/$rel" -o "$dest" || { err "Не удалось скачать модуль $rel"; return 1; }
    elif has wget; then
        wget -qO "$dest" "$MODULES_RAW_BASE/$rel" || { err "Не удалось скачать модуль $rel"; return 1; }
    else
        err "Нужен curl или wget для докачки модулей."; return 1
    fi
}

load_modules() {
    bootstrap_module lib/platform.sh || exit 1
    bootstrap_module lib/common.sh || exit 1
    bootstrap_module lib/menu.sh || exit 1
    bootstrap_module lib/loader.sh || exit 1
    # shellcheck disable=SC1090
    source "$MODULES_DIR/lib/common.sh"
    # shellcheck disable=SC1090
    source "$MODULES_DIR/lib/menu.sh"
    # shellcheck disable=SC1090
    source "$MODULES_DIR/lib/loader.sh"
}

show_help() {
    cat <<EOF
${BOLD}Arch Multitool v4${NC} (GUI + modules)
Использование: bash arch_multitool.sh [опция]
  -h, --help     Справка
  -a, --audit    Быстрый аудит (базовый)
  -f, --full     Авто-установка базового профиля (без меню)
Без опций — интерактивное меню.
Модули: ./modules или авто-докачка из ${REPO_SLUG}
EOF
}

quick_audit() {
    echo -e "${BOLD}== Быстрый аудит ==${NC}"
    echo "Host: $(hostnamectl --static 2>/dev/null || hostname)"
    echo "OS: $(. /etc/os-release 2>/dev/null; echo "${PRETTY_NAME:-unknown}")"
    echo "Kernel: $(uname -r)"
    echo "Disk:"; df -h / | tail -1
    echo "Mem:"; free -h | awk '/Mem:/ {print $3 "/" $2}'
    if has pacman; then echo "Pacman pkgs: $(pacman -Qq 2>/dev/null | wc -l)"; fi
    if has flatpak; then echo "Flatpak: $(flatpak list --app 2>/dev/null | wc -l) apps"; fi
}

main_menu() {
    while true; do
        menu_select "Arch Multitool v4" \
            "1|Полная интерактивная установка (галочки по разделам)" \
            "2|Установка ПО / фетчи / пресеты" \
            "3|Применить конфиги (stylish/end-4/mango/fastfetch)" \
            "4|Обновить систему" \
            "5|Аудит системы" \
            "0|Выход" || exit 0
        case "$MENU_CHOICE" in
            1) run_action full_interactive; pause ;;
            2) run_action software_menu ;;
            3) run_action apply_configs; pause ;;
            4) run_action update_system; pause ;;
            5) run_action quick_audit; pause ;;
            0) exit 0 ;;
        esac
    done
}

case "${1:-}" in
    -h|--help) show_help; exit 0 ;;
    -a|--audit) quick_audit; exit 0 ;;
    -f|--full) load_modules; run_action full_auto; exit 0 ;;
    "") load_modules; main_menu ;;
    *) err "Неизвестная опция: $1"; show_help; exit 1 ;;
esac
