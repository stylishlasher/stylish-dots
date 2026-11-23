#!/usr/bin/env bash
# ==============================================================================
# LINUX MULTITOOL (Debian) — установщик (bootstrap)
# ==============================================================================
# Ставит лаунчер, modules/ и config/ в ~/.local/share/arch-multitool и запускает.
# Загрузка динамическая: из git берутся только нужные пути (sparse + blob:none),
# git проверяет SHA объектов, всё содержимое дополнительно проходит bash -n.
# Новый набор собирается в отдельном каталоге, проверяется целиком и включается
# одним rename символьной ссылки current -> releases/<id>; есть откат.
# Повторный запуск проверяет весь набор и работает без сети. --refresh обновляет его.
#
# Быстрый запуск:
#   curl -fsSL https://raw.githubusercontent.com/stylishlasher/stylish-dots/main/install/install_debian.sh | bash
#
# Полная установка без меню:
#   curl -fsSL https://raw.githubusercontent.com/stylishlasher/stylish-dots/main/install/install_debian.sh | bash -s -- -f
#
# Обновить лаунчер и кэш:
#   bash install/install_debian.sh --refresh
# ==============================================================================

set -euo pipefail

# ------------------------------- Настройки -----------------------------------
REPO_SLUG="${REPO_SLUG:-stylishlasher/stylish-dots}"
REPO_BRANCH="${REPO_BRANCH:-main}"
REPO_URL="https://github.com/${REPO_SLUG}.git"

# current — символьная ссылка на releases/<id>; переключается одним rename.
INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/arch-multitool"
CURRENT="$INSTALL_DIR/current"
MULTITOOL="$CURRENT/arch_multitool_debian.sh"
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
  ║        D E B I A N   M U L T I T O O L        ║
  ║      установка · настройка · обслуживание     ║
  ╚═══════════════════════════════════════════════╝
ASCII
    printf '%s' "${N}" >&2
    echo >&2
}

# --------------------------------- Проверки ----------------------------------
[[ "$(uname -s)" == "Linux" ]] || die "Скрипт предназначен для Linux."
command -v apt-get >/dev/null 2>&1 || die "apt-get не найден — нужна Debian/Ubuntu-based система."
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
[[ ! -e "$CURRENT" || -L "$CURRENT" ]] || die "$CURRENT занят не-символьной ссылкой — откат невозможен."

ensure_git() {
    command -v git >/dev/null 2>&1 && return 0
    say "Устанавливаю git (он проверит целостность загружаемых файлов)..."
    sudo apt-get update || die "Не удалось обновить список пакетов."
    sudo apt-get install -y git || die "Не удалось установить git."
}

# Полная проверка набора: лаунчер, обязательные модули и конфиги, синтаксис .sh.
verify_bundle() {
    local dir="$1" f
    [[ -f "$dir/$LAUNCHER" ]] || return 1
    bash -n "$dir/$LAUNCHER" || return 1
    [[ -f "$dir/modules/lib/multitool.sh" && -f "$dir/modules/lib/i18n.sh" && -f "$dir/modules/lib/common.sh" ]] || return 1
    [[ -d "$dir/config/fastfetch" && -d "$dir/config/end4" ]] || return 1
    while IFS= read -r -d '' f; do bash -n "$f" || return 1; done < <(find "$dir/modules" -type f -name '*.sh' -print0 2>/dev/null)
}

# Собираем новый набор в releases/<id>, проверяем его и переключаем current одним rename.
publish_bundle() {
    local src="$1" id="$2" rel="releases/$id" stage="$INSTALL_DIR/releases/$id"
    local prev="" backup="" newlink="" switched=0
    mkdir -p "$INSTALL_DIR/releases" || die "Не удалось создать каталог releases."
    rm -rf "$stage"
    cp -a "$src" "$stage" || die "Не удалось подготовить новый набор."
    chmod +x "$stage/$LAUNCHER" || die "Не удалось сделать лаунчер исполняемым."
    if ! verify_bundle "$stage"; then
        rm -rf "$stage"
        die "Новый набор не прошёл проверку целостности."
    fi

    if [[ -L "$CURRENT" ]]; then
        prev="$(readlink "$CURRENT")"
        backup="$(mktemp -d "$INSTALL_DIR/.lnk.XXXXXX")" || die "Не удалось зарезервировать имя для отката."
        rmdir "$backup"
        cp -P "$CURRENT" "$backup" || die "Не удалось сохранить прежнюю ссылку."
    fi
    newlink="$(mktemp -d "$INSTALL_DIR/.lnk.XXXXXX")" || die "Не удалось зарезервировать имя ссылки."
    rmdir "$newlink"
    ln -s "$rel" "$newlink" || die "Не удалось создать новую ссылку."

    if mv -Tf "$newlink" "$CURRENT" && verify_bundle "$CURRENT"; then
        switched=1
    fi
    if (( ! switched )); then
        if [[ -n "$backup" ]]; then
            mv -Tf "$backup" "$CURRENT" || die "Не удалось откатить ссылку: $backup"
        else
            rm -f "$CURRENT"
        fi
        rm -rf "$stage"
        die "Не удалось переключить набор — прежняя версия восстановлена."
    fi

    rm -f "$backup"
    # Предыдущий release остаётся доступным для отката; удаляем только более старые.
    local old
    while IFS= read -r old; do
        [[ "$old" == "$id" || "$INSTALL_DIR/releases/$old" == "$INSTALL_DIR/$prev" ]] && continue
        rm -rf "$INSTALL_DIR/releases/$old"
    done < <(find "$INSTALL_DIR/releases" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -r | tail -n +3)
}

# Динамическая загрузка: только лаунчер, modules/ и config/, ничего лишнего.
fetch_bundle() {
    local tmp id
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
    id="$(date -u +%Y%m%dT%H%M%S)-$$"
    publish_bundle "$tmp" "$id"
    rm -rf "$tmp"
}

# -------------------------- Лаунчер + кэш модулей -----------------------------
if [[ "$REFRESH" == "1" ]] || ! verify_bundle "$CURRENT"; then
    fetch_bundle
else
    say "Набор проверен — работаю офлайн (--refresh для обновления)."
fi

ok "Мультитул готов: $MULTITOOL"
ok "Модули: $CURRENT/modules · конфиги: $CURRENT/config"
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
