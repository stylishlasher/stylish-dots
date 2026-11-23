#!/usr/bin/env bash
# Создаёт/проверяет подписанный манифест набора: лаунчеры + modules/ + config/.
# Приватный ключ НЕ хранится в репозитории: STYLISH_SIGNING_KEY или ~/.local/share/stylish-dots/signing.key.
# Публичный ключ bundle.pub дублируется в оба install/*.sh — репозиторий не меняет якорь доверия.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

MANIFEST=bundle.sha256
SIG="$MANIFEST.sig"
PUB=bundle.pub
KEY="${STYLISH_SIGNING_KEY:-$HOME/.local/share/stylish-dots/signing.key}"
PATHS=(arch_multitool.sh arch_multitool_debian.sh modules config)
# Те же исключения, что и у bootstrap в tar: сборка не попадает в кэш.
FIND_EXPR=( -path '*/target' -prune -o -path '*__pycache__' -prune -o )

die() { printf '%s\n' "$*" >&2; exit 1; }

build_manifest() {
    {
        echo '# stylish-dots bundle v2'
        find "${PATHS[@]}" "${FIND_EXPR[@]}" -type f -printf '# mode %m %p\n' | LC_ALL=C sort
        find "${PATHS[@]}" "${FIND_EXPR[@]}" -type l -printf '# link %p -> %l\n' | LC_ALL=C sort
        find "${PATHS[@]}" "${FIND_EXPR[@]}" -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum
    }
}

if [[ "${1:-}" == "--check" ]]; then
    [[ -s "$PUB" && -s "$MANIFEST" && -s "$SIG" ]] || die "Нет $PUB, $MANIFEST или $SIG."
    openssl dgst -sha256 -verify "$PUB" -signature "$SIG" "$MANIFEST" >/dev/null || die "Подпись манифеста недействительна."
    tmp="$(mktemp)"
    trap 'rm -f "$tmp"' EXIT
    build_manifest > "$tmp"
    cmp -s "$tmp" "$MANIFEST" || die "Манифест не соответствует файлам набора."
    echo "OK: манифест подписан и соответствует набору."
    exit 0
fi

[[ -f "$KEY" ]] || die "Нет приватного ключа: $KEY"
build_manifest > "$MANIFEST"
openssl dgst -sha256 -sign "$KEY" -out "$SIG" "$MANIFEST"
openssl pkey -in "$KEY" -pubout -out "$PUB" 2>/dev/null
echo "OK: $MANIFEST, $SIG, $PUB обновлены."
