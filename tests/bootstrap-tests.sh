#!/usr/bin/env bash
# Тесты bootstrap-установщиков: кэш modules/config, офлайн-повтор, --refresh.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "PASS: $*"; }

run_variant() {
    local script="$1" launcher="$2" pkg="$3"
    local tmp repo home data
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/stylish-bootstrap-test.XXXXXX")"
    repo="$tmp/repo"; home="$tmp/home"; data="$home/.local/share"
    mkdir -p "$repo/install" "$repo/modules/lib" "$repo/config/fastfetch" "$tmp/bin"
    cp "$ROOT/install/$script" "$repo/install/$script"
    printf '#!/usr/bin/env bash\nprintf "ARGS:%%s\\n" "$*"\n' > "$repo/$launcher"
    echo marker > "$repo/modules/lib/multitool.sh"
    echo preset > "$repo/config/fastfetch/config.jsonc"
    printf '#!/usr/bin/env bash\nexit 0\n' > "$tmp/bin/$pkg"

    local out
    if ! out="$(PATH="$tmp/bin:$PATH" HOME="$home" XDG_DATA_HOME="$data" \
        bash "$repo/install/$script" -a --refresh 2>&1)"; then
        echo "$out" >&2; fail "$script: first run failed"
    fi
    [[ -x "$data/arch-multitool/$launcher" ]] || fail "$script: launcher not installed"
    [[ -f "$data/arch-multitool/modules/lib/multitool.sh" ]] || fail "$script: modules cache missing"
    [[ -f "$data/arch-multitool/config/fastfetch/config.jsonc" ]] || fail "$script: config cache missing"
    grep -q '^ARGS:-a$' <<<"$out" || { echo "$out" >&2; fail "$script: --refresh leaked to multitool"; }
    pass "$script: installs launcher + modules + config"

    echo edited > "$data/arch-multitool/modules/lib/multitool.sh"
    PATH="$tmp/bin:$PATH" HOME="$home" XDG_DATA_HOME="$data" \
        bash "$repo/install/$script" -h >/dev/null 2>&1 || fail "$script: cached run failed"
    [[ "$(cat "$data/arch-multitool/modules/lib/multitool.sh")" == edited ]] || fail "$script: cache overwritten without --refresh"
    pass "$script: cached run works offline"

    PATH="$tmp/bin:$PATH" HOME="$home" XDG_DATA_HOME="$data" \
        bash "$repo/install/$script" --refresh >/dev/null 2>&1 || fail "$script: refresh failed"
    [[ "$(cat "$data/arch-multitool/modules/lib/multitool.sh")" == marker ]] || fail "$script: --refresh did not refresh cache"
    pass "$script: --refresh re-copies cache"
    rm -rf "$tmp"
}

run_variant install.sh arch_multitool.sh pacman
run_variant install_debian.sh arch_multitool_debian.sh apt-get

echo "ALL BOOTSTRAP TESTS PASSED"
