#!/usr/bin/env bash
# ==============================================================================
# ARCH MULTITOOL — установщик (bootstrap)
# ==============================================================================
# Ставит лаунчеры, modules/ и config/ в ~/.local/share/arch-multitool и запускает.
# Загрузка динамическая: из git берутся только нужные пути (sparse + blob:none).
# Набор проверяется по подписанному манифесту: SHA-256 содержимого, права доступа
# и символьные ссылки. Публичный ключ вшит сюда — подмена файлов вместе с
# манифестом не пройдёт проверку. bash -n дополнительно проверяет скрипты.
# Новый набор собирается в отдельном каталоге, проверяется целиком и включается
# одним rename символьной ссылки current -> releases/<id>; есть откат.
# Повторный запуск проверяет весь набор и работает без сети. --refresh обновляет его.
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

# Якорь доверия: публичный ключ вшит в установщик, а не берётся из репозитория
# или из окружения. Подменить его можно только изменив сам установщик.
BUNDLE_PUBKEY="$(cat <<'SD_PUBKEY'
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAlcXFELtdbF+4vzRC2O9+
sN/el2OncAavgxdEYk0ZRTtnVKKjhylXB99qljqja9AtwaDywEE2DBjViTb275s9
QaNOfO+g/+eG211Q7sq24QfsGztX1m5d3ACCbDI5ABQvBNd7e93EsOHCtdqgySNm
Go1/lwe7SgSpQDyJCb+9jBQTaZGA4nV53jXGYH1TC5TRLI2oVXa02cnkO4+4Gw2A
CPrCoR9Vlts3EEpskk77IaSypvC6dJNrOnsRYSxCqnbKhF5JLypOwAtAv6Fmd7wB
d7H+tTVegW8CgKDzDXoLIPrSbL8tA4plb4h52jwL9zxlLTF/Nd5ntPGukmPXjjqL
yQIDAQAB
-----END PUBLIC KEY-----
SD_PUBKEY
)"
MANIFEST=bundle.sha256
SIG="$MANIFEST.sig"

# current — символьная ссылка на releases/<id>; переключается одним rename.
INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/arch-multitool"
CURRENT="$INSTALL_DIR/current"
MULTITOOL="$CURRENT/arch_multitool.sh"
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
command -v sha256sum >/dev/null 2>&1 || die "sha256sum не найден — нужен для проверки содержимого набора."
command -v openssl >/dev/null 2>&1 || die "openssl не найден — нужен для проверки подписи набора."

banner
export STYLISH_BOOTSTRAPPED=1 # лаунчеры пропускают только запуск через bootstrap

# --refresh не пробрасываем в мультитул
REFRESH=0
ARGS=()
for a in "$@"; do
    if [[ "$a" == "--refresh" ]]; then REFRESH=1; else ARGS+=("$a"); fi
done
if (( ${#ARGS[@]} )); then set -- "${ARGS[@]}"; else set --; fi

# Ищем локальную копию с лаунчерами, modules/, config/ и подписанным манифестом
LOCAL_DIR=""
SELF="${BASH_SOURCE[0]:-}"
if [[ -n "$SELF" && -f "$SELF" ]]; then
    self_dir="$(cd -- "$(dirname -- "$SELF")" && pwd -P)"
    for cand in "$self_dir" "$self_dir/.."; do
        if [[ -f "$cand/arch_multitool.sh" && -f "$cand/arch_multitool_debian.sh" \
           && -f "$cand/modules/lib/multitool.sh" && -d "$cand/config" \
           && -s "$cand/$MANIFEST" && -s "$cand/$SIG" ]]; then
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
    sudo pacman -S --needed --noconfirm git || die "Не удалось установить git."
}

# Подпись манифеста + SHA-256 файлов + права доступа + символьные ссылки.
verify_bundle() {
    local dir="$1" f line rest path target mode expected actual links
    [[ -f "$dir/arch_multitool.sh" && -f "$dir/arch_multitool_debian.sh" ]] || return 1
    bash -n "$dir/arch_multitool.sh" || return 1
    bash -n "$dir/arch_multitool_debian.sh" || return 1
    [[ -f "$dir/modules/lib/multitool.sh" && -f "$dir/modules/lib/i18n.sh" && -f "$dir/modules/lib/common.sh" ]] || return 1
    [[ -d "$dir/config/fastfetch" && -d "$dir/config/end4" ]] || return 1
    while IFS= read -r -d '' f; do bash -n "$f" || return 1; done < <(find "$dir/modules" -type f -name '*.sh' -print0 2>/dev/null)
    [[ -s "$dir/$MANIFEST" && -s "$dir/$SIG" ]] || return 1
    openssl dgst -sha256 -verify <(printf '%s\n' "$BUNDLE_PUBKEY") -signature "$dir/$SIG" "$dir/$MANIFEST" >/dev/null 2>&1 || return 1
    (cd "$dir" && sha256sum --check --quiet "$MANIFEST") >/dev/null 2>&1 || return 1
    expected=$(grep -c '^[0-9a-f]\{64\}  ' "$dir/$MANIFEST" || true)
    actual=$(find "$dir/" -type f ! -name "$MANIFEST" ! -name "$SIG" -print | wc -l)
    [[ "$expected" -eq "$actual" ]] || return 1
    links=$(grep -c '^# link ' "$dir/$MANIFEST" || true)
    [[ "$links" -eq "$(find "$dir/" -type l -print | wc -l)" ]] || return 1
    while IFS= read -r line; do
        case "$line" in
            '# mode '*)
                rest="${line#\# mode }"; mode="${rest%% *}"; path="${rest#* }"
                [[ "$(stat -c %a "$dir/$path")" == "$mode" ]] || return 1 ;;
            '# link '*)
                rest="${line#\# link }"; path="${rest%% -> *}"; target="${rest#* -> }"
                [[ -L "$dir/$path" && "$(readlink "$dir/$path")" == "$target" ]] || return 1 ;;
        esac
    done < "$dir/$MANIFEST"
    return 0
}

# Собираем новый набор в releases/<id>, проверяем его и переключаем current одним rename.
publish_bundle() {
    local src="$1" id="$2" rel="releases/$id" stage="$INSTALL_DIR/releases/$id"
    local prev="" backup="" newlink="" switched=0
    mkdir -p "$INSTALL_DIR/releases" || die "Не удалось создать каталог releases."
    rm -rf "$stage"
    cp -a "$src" "$stage" || die "Не удалось подготовить новый набор."
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

# Динамическая загрузка: только лаунчеры, modules/, config/ и подписанный манифест.
fetch_bundle() {
    local tmp id
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/stylish-bootstrap.XXXXXX")" || die "Не удалось создать временный каталог."
    if [[ -n "$LOCAL_DIR" ]]; then
        say "Копирую лаунчеры, modules/, config/ и манифест из $LOCAL_DIR"
        # tar с исключениями: в кэш не попадают target/, __pycache__ и прочие артефакты сборки
        tar -C "$LOCAL_DIR" -cf - --exclude='*/target' --exclude='*__pycache__' \
            arch_multitool.sh arch_multitool_debian.sh modules config "$MANIFEST" "$SIG" | tar -xf - -C "$tmp" \
            || die "Не удалось скопировать файлы из локальной копии."
    else
        ensure_git
        say "Скачиваю только нужные пути ${B}${REPO_SLUG}${N}${C} (ветка ${REPO_BRANCH}); git проверяет SHA объектов..."
        git clone --depth 1 --filter=blob:none --sparse --branch "$REPO_BRANCH" "$REPO_URL" "$tmp/repo" \
            || die "Не удалось скачать репозиторий."
        git -C "$tmp/repo" sparse-checkout set modules config || die "Не удалось выбрать нужные пути."
        say "Коммит: $(git -C "$tmp/repo" rev-parse --short HEAD)"
        cp "$tmp/repo/arch_multitool.sh" "$tmp/repo/arch_multitool_debian.sh" "$tmp/repo/$MANIFEST" "$tmp/repo/$SIG" "$tmp/" \
            || die "В репозитории нет лаунчеров или подписанного манифеста."
        mv "$tmp/repo/modules" "$tmp/modules" || die "В репозитории нет modules/."
        mv "$tmp/repo/config" "$tmp/config" || die "В репозитории нет config/."
        rm -rf "$tmp/repo" # в наборе не должно быть клона с .git и дублями файлов
    fi
    verify_bundle "$tmp" || die "Набор не прошёл проверку подписи и целостности."
    id="$(date -u +%Y%m%dT%H%M%S)-$$"
    publish_bundle "$tmp" "$id"
    rm -rf "$tmp"
}

# -------------------------- Лаунчер + кэш модулей -----------------------------
if [[ "$REFRESH" == "1" ]] || ! verify_bundle "$CURRENT"; then
    fetch_bundle
else
    say "Набор проверен (подпись, содержимое, права) — работаю офлайн (--refresh для обновления)."
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
