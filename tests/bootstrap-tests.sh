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
    for m in multitool i18n common; do echo marker > "$repo/modules/lib/$m.sh"; done
    mkdir -p "$repo/config/end4"
    echo preset > "$repo/config/fastfetch/config.jsonc"
    mkdir -p "$repo/config/fetches/stylish-fetches/target" "$repo/config/bin/__pycache__"
    echo artifact > "$repo/config/fetches/stylish-fetches/target/keyfetch"
    echo artifact > "$repo/config/bin/__pycache__/x.pyc"
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
    [[ ! -e "$data/arch-multitool/config/fetches/stylish-fetches/target" ]] || fail "$script: build artifacts in cache"
    [[ ! -e "$data/arch-multitool/config/bin/__pycache__" ]] || fail "$script: __pycache__ in cache"
    pass "$script: build artifacts excluded"

    echo edited > "$data/arch-multitool/modules/lib/multitool.sh"
    PATH="$tmp/bin:$PATH" HOME="$home" XDG_DATA_HOME="$data" \
        bash "$repo/install/$script" -h >/dev/null 2>&1 || fail "$script: cached run failed"
    [[ "$(cat "$data/arch-multitool/modules/lib/multitool.sh")" == edited ]] || fail "$script: cache overwritten without --refresh"
    pass "$script: cached run works offline"

    PATH="$tmp/bin:$PATH" HOME="$home" XDG_DATA_HOME="$data" \
        bash "$repo/install/$script" --refresh >/dev/null 2>&1 || fail "$script: refresh failed"
    [[ "$(cat "$data/arch-multitool/modules/lib/multitool.sh")" == marker ]] || fail "$script: --refresh did not refresh cache"
    pass "$script: --refresh re-copies cache"

    rm -f "$repo/modules/lib/i18n.sh"
    if PATH="$tmp/bin:$PATH" HOME="$home" XDG_DATA_HOME="$data" \
        bash "$repo/install/$script" --refresh >/dev/null 2>&1; then
        fail "$script: broken bundle was accepted"
    fi
    [[ -f "$data/arch-multitool/modules/lib/multitool.sh" ]] || fail "$script: bad refresh destroyed the cache"
    pass "$script: broken bundle rejected, cache intact"
    rm -rf "$tmp"
}

# Проверка сетевого пути: локального репо нет, модули приходят через git clone.
run_clone_variant() {
    local script="$1" launcher="$2" pkg="$3"
    local tmp fixture home data
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/stylish-clone-test.XXXXXX")"
    fixture="$tmp/fixture"; home="$tmp/home"; data="$home/.local/share"
    mkdir -p "$fixture/modules/lib" "$fixture/config/fastfetch" "$fixture/config/end4" "$tmp/bin" "$tmp/standalone"
    for m in multitool i18n common; do echo marker > "$fixture/modules/lib/$m.sh"; done
    echo preset > "$fixture/config/fastfetch/config.jsonc"
    cp "$ROOT/install/$script" "$tmp/standalone/$script"
    printf '#!/usr/bin/env bash\nexit 0\n' > "$tmp/bin/$pkg"

    cat > "$tmp/bin/git" <<EOF
#!/usr/bin/env bash
dest="\${@: -1}"
mkdir -p "\$dest"
cp -a "$fixture/modules" "\$dest/modules"
cp -a "$fixture/config" "\$dest/config"
EOF
    cat > "$tmp/bin/curl" <<'EOF'
#!/usr/bin/env bash
out="${@: -1}"
printf '#!/usr/bin/env bash\nprintf "ARGS:%%s\\n" "$*"\n' > "$out"
EOF
    chmod +x "$tmp/bin/git" "$tmp/bin/curl" "$tmp/bin/$pkg"

    local out
    if ! out="$(PATH="$tmp/bin:$PATH" HOME="$home" XDG_DATA_HOME="$data" \
        bash "$tmp/standalone/$script" -a 2>&1)"; then
        echo "$out" >&2; fail "$script: clone path failed"
    fi
    [[ -f "$data/arch-multitool/$launcher" ]] || fail "$script: clone path: launcher missing"
    [[ -f "$data/arch-multitool/modules/lib/i18n.sh" ]] || fail "$script: clone path: modules missing"
    [[ -f "$data/arch-multitool/config/fastfetch/config.jsonc" ]] || fail "$script: clone path: config missing"
    grep -q 'git проверяет SHA' <<<"$out" || { echo "$out" >&2; fail "$script: clone path not used"; }
    grep -q '^ARGS:-a$' <<<"$out" || { echo "$out" >&2; fail "$script: clone path: args lost"; }
    pass "$script: git clone path installs full bundle"
    rm -rf "$tmp"
}

run_variant install.sh arch_multitool.sh pacman
run_variant install_debian.sh arch_multitool_debian.sh apt-get
run_clone_variant install.sh arch_multitool.sh pacman
run_clone_variant install_debian.sh arch_multitool_debian.sh apt-get

echo "ALL BOOTSTRAP TESTS PASSED"
