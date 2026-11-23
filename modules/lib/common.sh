#!/usr/bin/env bash
# Common helpers for stylish-dots modules.
# Опции shell (set -e/-u/pipefail) задаёт entry point, библиотека их не меняет.

_I18N="$(dirname -- "${BASH_SOURCE[0]}")/i18n.sh"
[[ -f "$_I18N" ]] && source "$_I18N"
unset _I18N

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

pause() { echo; read -rp "${YELLOW}$(t pause)${NC}" _ || true; }
is_interactive() { [[ -t 0 && -t 1 ]]; }
confirm() { local ans=""; read -rp "${YELLOW}$1 [y/N]: ${NC}" ans || return 1; [[ "$ans" =~ ^[YyДдDd]$ ]]; }
has() { command -v "$1" &>/dev/null; }

ensure_sudo() {
    if [[ $EUID -eq 0 ]]; then err "$(t sudo_root)"; return 1; fi
    has sudo || { err "$(t sudo_missing)"; return 1; }
    sudo -v || return 1
    if [[ -z "$SUDO_KEEPALIVE_PID" ]]; then
        ( while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done ) 2>/dev/null &
        SUDO_KEEPALIVE_PID=$!
    fi
}

ensure_work_dir() { [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]] || WORK_DIR=$(mktemp -d /tmp/stylish-dots.XXXXXX); }
# return 0: иначе статус cleanup подменяет код выхода скрипта через EXIT trap
cleanup() { [[ -n "$SUDO_KEEPALIVE_PID" ]] && kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true; [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]] && rm -rf "$WORK_DIR"; return 0; }
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
    info "$(t downloading_configs)"
    curl -fsSL "$CONFIG_TARBALL" -o "$tar" || { err "$(t download_repo_failed)"; return 1; }
    mkdir -p "$WORK_DIR/repo"
    tar -xzf "$tar" -C "$WORK_DIR/repo" --strip-components=1
    CONFIGS_DIR="$WORK_DIR/repo/config"
    REPO_ROOT="$WORK_DIR/repo"
    export CONFIGS_DIR REPO_ROOT
    [[ -d "$CONFIGS_DIR" ]]
}

BACKUP_REGISTRY="${XDG_STATE_HOME:-$HOME/.local/state}/stylish-dots/backups.tsv"

backup_stamp() {
    printf '%s_%s' "$(date +%Y%m%d_%H%M%S_%N 2>/dev/null)" "$$"
}

backup_register() {
    local src="$1" bk="$2"
    mkdir -p "$(dirname "$BACKUP_REGISTRY")" || return 1
    printf '%s\t%s\t%s\n' "$(date '+%F %T')" "$src" "$bk" >> "$BACKUP_REGISTRY"
}

# Убираем записи о бэкапах, которых уже нет на диске.
backup_prune_registry() {
    [[ -f "$BACKUP_REGISTRY" ]] || return 0
    local tmp ts src bk kept=0 total=0
    tmp="$(mktemp "${BACKUP_REGISTRY}.tmp.XXXXXX")" || return 1
    while IFS=$'\t' read -r ts src bk; do
        [[ -n "$ts" && -n "$src" && -n "$bk" ]] || continue
        total=$((total+1))
        if [[ -e "$bk" || -L "$bk" ]]; then
            printf '%s\t%s\t%s\n' "$ts" "$src" "$bk" >> "$tmp" || { rm -f "$tmp"; return 1; }
            kept=$((kept+1))
        fi
    done < "$BACKUP_REGISTRY"
    if (( kept == total )); then rm -f "$tmp"; return 0; fi
    mv -f "$tmp" "$BACKUP_REGISTRY" || { rm -f "$tmp"; return 1; }
}

stash_dir() {
    local dst="$1"
    [[ -e "$dst" || -L "$dst" ]] || return 0
    local bk="${dst}.bak.$(backup_stamp)" n=0
    while [[ -e "$bk" || -L "$bk" ]]; do
        n=$((n+1))
        bk="${dst}.bak.$(backup_stamp).$n"
    done
    if mv "$dst" "$bk"; then
        if backup_register "$dst" "$bk"; then
            info "Backup: $bk"
        else
            err "$(t backup_moved_unregistered "$bk")"
            if mv "$bk" "$dst" 2>/dev/null; then
                err "$(t path_restored "$dst")"
            else
                err "$(t restore_manually "$bk" "$dst")"
            fi
            return 1
        fi
    else
        err "$(t backup_move_failed "$dst" "$bk")"
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
