#!/usr/bin/env bash
# Common helpers for stylish-dots modules.

set -uo pipefail

: "${REPO_SLUG:=stylishlasher/stylish-dots}"
: "${REPO_BRANCH:=main}"
: "${MODULES_RAW_BASE:=https://raw.githubusercontent.com/${REPO_SLUG}/${REPO_BRANCH}/modules}"
: "${CONFIG_TARBALL:=https://codeload.github.com/${REPO_SLUG}/tar.gz/refs/heads/${REPO_BRANCH}}"
: "${SERPANTINUM_STATE_DIR:=${XDG_STATE_HOME:-$HOME/.local/state}/serpantinum}"
: "${THEME_DIR:=$SERPANTINUM_STATE_DIR/presets}"
: "${FISH_PLUGINS:=jorgebucaran/fisher ilancosman/tide@v6}"
: "${LOG_FILE:=${XDG_STATE_HOME:-$HOME/.local/state}/arch_multitool.log}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd 2>/dev/null || pwd)"
WORK_DIR=""
SUDO_KEEPALIVE_PID=""

if [[ -t 1 ]]; then
    RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'
    CYAN=$'\033[0;36m'; BOLD=$'\033[1m'; NC=$'\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; CYAN=''; BOLD=''; NC=''
fi

mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

log()  { printf '%s  %s\n' "$(date '+%F %T')" "$*" >> "$LOG_FILE" 2>/dev/null || true; }
info() { echo -e "${CYAN}$*${NC}"; log "INFO  $*"; }
warn() { echo -e "${YELLOW}$*${NC}"; log "WARN  $*"; }
ok()   { echo -e "${GREEN}[✓] $*${NC}"; log "OK    $*"; }
err()  { echo -e "${RED}[✗] $*${NC}" >&2; log "ERROR $*"; }

pause() { echo; read -rp "${YELLOW}Нажмите Enter для продолжения...${NC}" _; }
is_interactive() { [[ -t 0 && -t 1 ]]; }
confirm() { local ans; read -rp "${YELLOW}$1 [y/N]: ${NC}" ans; [[ "$ans" =~ ^[YyДд]$ ]]; }
has() { command -v "$1" &>/dev/null; }

ensure_sudo() {
    if [[ $EUID -eq 0 ]]; then err "Не запускайте скрипт от root."; return 1; fi
    has sudo || { err "sudo не установлен."; return 1; }
    sudo -v || return 1
    if [[ -z "$SUDO_KEEPALIVE_PID" ]]; then
        ( while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done ) 2>/dev/null &
        SUDO_KEEPALIVE_PID=$!
    fi
}

ensure_work_dir() { [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]] || WORK_DIR=$(mktemp -d /tmp/stylish-dots.XXXXXX); }
cleanup() { [[ -n "$SUDO_KEEPALIVE_PID" ]] && kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true; [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]] && rm -rf "$WORK_DIR"; }
trap cleanup EXIT INT TERM

resolve_configs() {
    # Prefer local repo config/
    local candidates=(
        "$SCRIPT_DIR/config"
        "$PWD/config"
        "${STYLISH_CONFIGS_DIR:-}"
    )
    local c
    for c in "${candidates[@]}"; do
        [[ -n "$c" && -d "$c" ]] && { CONFIGS_DIR="$c"; REPO_ROOT="$(cd "$c/.." && pwd)"; export CONFIGS_DIR REPO_ROOT; return 0; }
    done

    # download tarball
    ensure_work_dir
    local tar="$WORK_DIR/repo.tar.gz"
    info "Скачиваю конфиги/модули из GitHub..."
    curl -fsSL "$CONFIG_TARBALL" -o "$tar" || { err "Не удалось скачать репозиторий."; return 1; }
    mkdir -p "$WORK_DIR/repo"
    tar -xzf "$tar" -C "$WORK_DIR/repo" --strip-components=1
    CONFIGS_DIR="$WORK_DIR/repo/config"
    REPO_ROOT="$WORK_DIR/repo"
    export CONFIGS_DIR REPO_ROOT
    [[ -d "$CONFIGS_DIR" ]]
}

BACKUP_REGISTRY="${XDG_STATE_HOME:-$HOME/.local/state}/stylish-dots/backups.tsv"

backup_register() {
    local src="$1" bk="$2"
    mkdir -p "$(dirname "$BACKUP_REGISTRY")"
    printf '%s\t%s\t%s\n' "$(date '+%F %T')" "$src" "$bk" >> "$BACKUP_REGISTRY"
}

stash_dir() {
    local dst="$1"
    [[ -e "$dst" || -L "$dst" ]] || return 0
    local bk="${dst}.bak.$(date +%Y%m%d_%H%M%S)"
    if mv "$dst" "$bk"; then
        backup_register "$dst" "$bk"
        info "Backup: $bk"
    else
        err "Не удалось создать бэкап: $dst -> $bk"
        return 1
    fi
}

normalize_paths() {
    local target="$1"
    [[ -d "$target" ]] || return 0
    while IFS= read -r -d '' f; do
        sed -i "s#/home/[^/\"' ]*#${HOME}#g" "$f" 2>/dev/null || true
    done < <(find "$target" -type f -size -2M -print0 2>/dev/null)
}

source "$SCRIPT_DIR/modules/lib/platform.sh"
detect_platform
