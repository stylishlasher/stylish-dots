#!/usr/bin/env bash
# Common launcher for stylish-dots multitool.

set -uo pipefail

: "${REPO_SLUG:=stylishlasher/stylish-dots}"
: "${REPO_BRANCH:=main}"
: "${RAW_BASE:=https://raw.githubusercontent.com/${REPO_SLUG}/${REPO_BRANCH}}"
: "${MODULES_RAW_BASE:=${RAW_BASE}/modules}"
: "${CONFIG_TARBALL:=https://codeload.github.com/${REPO_SLUG}/tar.gz/refs/heads/${REPO_BRANCH}}"
: "${LOG_FILE:=${XDG_STATE_HOME:-$HOME/.local/state}/arch_multitool.log}"
export REPO_SLUG REPO_BRANCH RAW_BASE MODULES_RAW_BASE CONFIG_TARBALL

WORK_DIR=""
if [[ -n "${BASH_SOURCE[1]:-}" && "${BASH_SOURCE[1]}" != "bash" && -f "${BASH_SOURCE[1]}" ]]; then
    SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[1]}")" && pwd)"
elif [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
    SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
else
    SCRIPT_DIR="$(pwd)"
fi
MODULES_DIR="$SCRIPT_DIR/modules"
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

if [[ -t 1 ]]; then RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; CYAN=$'\033[0;36m'; BOLD=$'\033[1m'; NC=$'\033[0m'; else RED='';GREEN='';YELLOW='';CYAN='';BOLD='';NC=''; fi
info(){ echo -e "${CYAN}$*${NC}"; }
warn(){ echo -e "${YELLOW}$*${NC}"; }
err(){ echo -e "${RED}[✗] $*${NC}" >&2; }
ok(){ echo -e "${GREEN}[✓] $*${NC}"; }
has(){ command -v "$1" >/dev/null 2>&1; }
ensure_work_dir(){ [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]] || WORK_DIR="$(mktemp -d /tmp/stylish-dots.XXXXXX)"; }
cleanup(){ [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]] && rm -rf "$WORK_DIR"; return 0; }
trap cleanup EXIT INT TERM

# RU is the source language; i18n.sh overrides messages for en/ro when available.
declare -gA SD_MSG=()
t() {
    local msg="${SD_MSG[$1]:-$1}"
    shift
    local i=1 a
    for a in "$@"; do msg="${msg//\{$i\}/$a}"; i=$((i+1)); done
    printf '%s' "$msg"
}
if [[ -f "$MODULES_DIR/lib/i18n.sh" ]]; then source "$MODULES_DIR/lib/i18n.sh"; fi

bootstrap_module() {
    local rel="$1"
    local dest="$MODULES_DIR/$rel"
    [[ -f "$dest" ]] && return 0
    mkdir -p "$(dirname "$dest")"
    if has curl; then curl -fsSL "$MODULES_RAW_BASE/$rel" -o "$dest" || { err "$(t module_download_failed_short "$rel")"; return 1; }
    elif has wget; then wget -qO "$dest" "$MODULES_RAW_BASE/$rel" || { err "$(t module_download_failed_short "$rel")"; return 1; }
    else err "$(t need_curl_wget)"; return 1; fi
}

load_modules() {
    bootstrap_module lib/i18n.sh || exit 1
    source "$MODULES_DIR/lib/i18n.sh"
    bootstrap_module lib/platform.sh || exit 1
    bootstrap_module lib/common.sh || exit 1
    bootstrap_module lib/menu.sh || exit 1
    bootstrap_module lib/loader.sh || exit 1
    # shellcheck disable=SC1090
    source "$MODULES_DIR/lib/platform.sh"
    # shellcheck disable=SC1090
    source "$MODULES_DIR/lib/common.sh"
    # shellcheck disable=SC1090
    source "$MODULES_DIR/lib/menu.sh"
    # shellcheck disable=SC1090
    source "$MODULES_DIR/lib/loader.sh"
}

show_help() {
    cat <<EOF
${BOLD}${TOOL_NAME}${NC} (GUI + modules)
  -h, --help  $(t help)
  -a, --audit $(t audit_short)
  -f, --full  $(t full_auto_help)
$(t no_options_help)
$(t modules_help "$REPO_SLUG")
EOF
}

quick_audit() {
    echo -e "${BOLD}$(t audit_header)${NC}"
    echo "Host: $(hostnamectl --static 2>/dev/null || hostname 2>/dev/null || echo unknown)"
    local os_pretty="" os_id="" os_name=""
    if [[ -f /etc/os-release ]]; then . /etc/os-release; os_pretty="${PRETTY_NAME:-unknown}"; os_id="${ID:-}"; os_name="${NAME:-}"; fi
    echo "OS: ${os_pretty:-unknown}"
    if [[ "${PLATFORM:-}" == "arch" && ( "$os_id" == "cachyos" || "$os_name" == *CachyOS* ) ]]; then
        echo "Compat: CachyOS (Arch-compatible mode)"
    fi
    echo "Kernel: $(uname -r)"
    echo "Disk:"; df -h / | tail -1
    echo "Mem:"; free -h | awk '/Mem:/ {print $3 "/" $2}'
    has pacman && echo "Pacman pkgs: $(pacman -Qq 2>/dev/null | wc -l)"
    has dpkg && echo "DPKG pkgs: $(dpkg -l 2>/dev/null | grep -c '^ii')"
    has flatpak && echo "Flatpak: $(flatpak list --app 2>/dev/null | wc -l) apps"
}

main_menu() {
    while true; do
        menu_select "$TOOL_NAME" \
            "1|$(t menu_full)" \
            "2|$(t menu_dotfiles_only)" \
            "3|$(t menu_software)" \
            "4|$(t menu_apply)" \
            "5|$(t menu_backups)" \
            "6|Uninstall" \
            "7|$(t menu_update)" \
            "8|$(t menu_audit)" \
            "0|$(t menu_exit)" || exit 0
        case "$MENU_CHOICE" in
            1) run_action full_interactive; pause ;;
            2) run_action dotfiles_only; pause ;;
            3) run_action software_menu ;;
            4) run_action apply_configs; pause ;;
            5)
                menu_select "$(t backup_menu_title)" "1|$(t backup_menu_list)" "2|$(t backup_menu_restore)" "3|Rollback end4" "4|Rollback mango" "5|Rollback stylish" "0|$(t menu_back)" || true
                case "$MENU_CHOICE" in
                    1) run_action backup_list ;;
                    2) run_action restore_backup ;;
                    3) run_action restore_profile end4 ;;
                    4) run_action restore_profile mango ;;
                    5) run_action restore_profile stylish ;;
                esac
                pause ;;
            6) run_action uninstall; pause ;;
            7) run_action update_system; pause ;;
            8) run_action quick_audit; pause ;;
            0) exit 0 ;;
        esac
    done
}

multitool_main() {
    case "${1:-}" in
        -h|--help) show_help; exit 0 ;;
        -a|--audit) load_modules; quick_audit; exit 0 ;;
        -f|--full) load_modules; run_action full_auto; exit 0 ;;
        "") load_modules; main_menu ;;
        *) err "$(t unknown_option "$1")"; show_help; exit 1 ;;
    esac
}
