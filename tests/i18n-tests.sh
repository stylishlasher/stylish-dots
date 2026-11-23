#!/usr/bin/env bash
# Тесты локализации UI и переводов документации.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "PASS: $*"; }

I18N=modules/lib/i18n.sh

load_lang() {
    STYLISH_LANG="$1" bash -c 'source "$1"; printf "%s|%s|%s" "$STYLISH_LANG" "$(t menu_exit)" "$(t restore_manually a b)"' _ "$I18N"
}

[[ "$(load_lang en)" == 'en|Exit|Could not restore a -> b; restore manually' ]] || fail "EN translations"
[[ "$(load_lang ro)" == 'ro|Ieșire|Nu s-a putut restaura a -> b; restaurați manual' ]] || fail "RO translations"
[[ "$(load_lang ru)" == 'ru|Выход|Не удалось вернуть a -> b; восстанови вручную' ]] || fail "RU source strings"
pass "explicit STYLISH_LANG and placeholders"

[[ "$(LANG=ro_RO.UTF-8 STYLISH_LANG= bash -c 'source "$1"; echo "$STYLISH_LANG"' _ "$I18N")" == ro ]] || fail "LANG ro detection"
[[ "$(LANG=en_US.UTF-8 STYLISH_LANG= bash -c 'source "$1"; echo "$STYLISH_LANG"' _ "$I18N")" == en ]] || fail "LANG en detection"
[[ "$(LANG=C.UTF-8 STYLISH_LANG= bash -c 'source "$1"; echo "$STYLISH_LANG"' _ "$I18N")" == ru ]] || fail "unknown LANG fallback"
[[ "$(STYLISH_LANG=xx bash -c 'source "$1"; echo "$STYLISH_LANG"' _ "$I18N")" == ru ]] || fail "invalid STYLISH_LANG fallback"
pass "language auto-detection and fallback"

mapfile -t used < <(grep -rhoE --include='*.sh' '\$\(t [a-z_][a-z_0-9]*|\) t [a-z_][a-z_0-9]*' modules arch_multitool.sh arch_multitool_debian.sh | sed -E 's/.*t //' | sort -u)
((${#used[@]} > 0)) || fail "no translation keys found in UI code"
for lang in en ro; do
    mapfile -t defined < <(STYLISH_LANG="$lang" bash -c 'source "$1"; printf "%s\n" "${!SD_MSG[@]}"' _ "$I18N" | sort)
    for key in "${used[@]}"; do
        printf '%s\n' "${defined[@]}" | grep -Fxq "$key" || fail "$lang: missing key $key"
    done
done
pass "all UI keys translated in EN and RO"

for f in README.en.md README.ro.md modules/README.en.md modules/README.ro.md docs/en/index.html docs/ro/index.html; do
    [[ -s "$f" ]] || fail "missing translation: $f"
    bad=$(grep -E '[А-Яа-яЁё]' "$f" | grep -v 'Русский' || true)
    [[ -z "$bad" ]] || fail "untranslated Cyrillic in $f: $bad"
done
pass "documentation translations present"

echo "ALL I18N TESTS PASSED"