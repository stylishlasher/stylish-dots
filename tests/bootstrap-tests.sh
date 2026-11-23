#!/usr/bin/env bash
# Тесты bootstrap: динамическая загрузка нужных путей, проверка целостности, офлайн, откат.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "PASS: $*"; }

stub_launcher() {
    printf '#!/usr/bin/env bash\nprintf "ARGS:%%s\\n" "$*"\n' > "$1"
}

run_variant() {
    local script="$1" launcher="$2" pkg="$3"
    local tmp repo home data offlinebin
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/stylish-bootstrap-test.XXXXXX")"
    repo="$tmp/repo"; home="$tmp/home"; data="$home/.local/share"; offlinebin="$tmp/offlinebin"
    mkdir -p "$repo/install" "$repo/modules/lib" "$repo/config/fastfetch" "$tmp/bin" "$offlinebin"
    cp "$ROOT/install/$script" "$repo/install/$script"
    stub_launcher "$repo/$launcher"
    for m in multitool i18n common; do echo marker > "$repo/modules/lib/$m.sh"; done
    mkdir -p "$repo/config/end4"
    echo preset > "$repo/config/fastfetch/config.jsonc"
    mkdir -p "$repo/config/fetches/stylish-fetches/target" "$repo/config/bin/__pycache__"
    echo artifact > "$repo/config/fetches/stylish-fetches/target/keyfetch"
    echo artifact > "$repo/config/bin/__pycache__/x.pyc"
    printf '#!/usr/bin/env bash\nexit 0\n' > "$tmp/bin/$pkg"
    cp "$tmp/bin/$pkg" "$offlinebin/$pkg"

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

    # Настоящий офлайн: в PATH нет ни git, ни curl, ни даже пакетного менеджера.
    echo edited > "$data/arch-multitool/modules/lib/multitool.sh"
    if ! out="$(PATH="$offlinebin:/usr/bin:/bin" HOME="$home" XDG_DATA_HOME="$data" \
        bash "$repo/install/$script" -h 2>&1)"; then
        echo "$out" >&2; fail "$script: offline run failed"
    fi
    grep -q 'работаю офлайн' <<<"$out" || { echo "$out" >&2; fail "$script: offline message missing"; }
    [[ "$(cat "$data/arch-multitool/modules/lib/multitool.sh")" == edited ]] || fail "$script: cache overwritten offline"
    pass "$script: cached run works with no git/curl in PATH"

    PATH="$tmp/bin:$PATH" HOME="$home" XDG_DATA_HOME="$data" \
        bash "$repo/install/$script" --refresh >/dev/null 2>&1 || fail "$script: refresh failed"
    [[ "$(cat "$data/arch-multitool/modules/lib/multitool.sh")" == marker ]] || fail "$script: --refresh did not refresh cache"
    pass "$script: --refresh re-copies cache"

    rm -f "$repo/modules/lib/i18n.sh"
    if PATH="$tmp/bin:$PATH" HOME="$home" XDG_DATA_HOME="$data" \
        bash "$repo/install/$script" --refresh >/dev/null 2>&1; then
        fail "$script: broken bundle was accepted"
    fi
    [[ -f "$data/arch-multitool/modules/lib/i18n.sh" ]] || fail "$script: bad refresh destroyed the cache"
    pass "$script: broken bundle rejected, cache intact"
    echo marker > "$repo/modules/lib/i18n.sh"

    printf 'if [[ ' > "$repo/$launcher"
    if PATH="$tmp/bin:$PATH" HOME="$home" XDG_DATA_HOME="$data" \
        bash "$repo/install/$script" --refresh >/dev/null 2>&1; then
        fail "$script: broken launcher was accepted"
    fi
    if ! out="$(PATH="$offlinebin:/usr/bin:/bin" HOME="$home" XDG_DATA_HOME="$data" \
        bash "$repo/install/$script" -a 2>&1)"; then
        echo "$out" >&2; fail "$script: launcher not restored"
    fi
    grep -q '^ARGS:-a$' <<<"$out" || { echo "$out" >&2; fail "$script: restored launcher broken"; }
    pass "$script: broken launcher rejected, old one restored"
    rm -rf "$tmp"
}

# Сетевой путь: локального репо нет, всё приходит через sparse git clone.
run_clone_variant() {
    local script="$1" launcher="$2" pkg="$3"
    local tmp fixture home data offlinebin
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/stylish-clone-test.XXXXXX")"
    fixture="$tmp/fixture"; home="$tmp/home"; data="$home/.local/share"; offlinebin="$tmp/offlinebin"
    mkdir -p "$fixture/modules/lib" "$fixture/config/fastfetch" "$fixture/config/end4" \
        "$tmp/bin" "$offlinebin" "$tmp/standalone"
    for m in multitool i18n common; do echo marker > "$fixture/modules/lib/$m.sh"; done
    echo preset > "$fixture/config/fastfetch/config.jsonc"
    stub_launcher "$fixture/$launcher"
    cp "$ROOT/install/$script" "$tmp/standalone/$script"
    printf '#!/usr/bin/env bash\nexit 0\n' > "$tmp/bin/$pkg"
    cp "$tmp/bin/$pkg" "$offlinebin/$pkg"

    cat > "$tmp/bin/git" <<EOF
#!/usr/bin/env bash
if [[ "\${1:-}" == "clone" ]]; then
    [[ " \$* " == *" --filter=blob:none "* ]] || { echo NO_FILTER >&2; exit 3; }
    [[ " \$* " == *" --sparse "* ]] || { echo NO_SPARSE >&2; exit 3; }
    dest="\${@: -1}"
    mkdir -p "\$dest"
    cp -a "$fixture/modules" "\$dest/modules"
    cp -a "$fixture/config" "\$dest/config"
    cp -a "$fixture/$launcher" "\$dest/$launcher"
    exit 0
fi
if [[ "\${1:-}" == "-C" ]]; then
    shift 2
    case "\${1:-}" in
        sparse-checkout) [[ "\$*" == *"modules config"* ]] || exit 4; exit 0 ;;
        rev-parse) echo stubsha; exit 0 ;;
    esac
fi
exit 5
EOF
    cat > "$tmp/bin/curl" <<'EOF'
#!/usr/bin/env bash
echo "CURL MUST NOT BE USED" >&2
exit 9
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
    grep -q 'только нужные пути' <<<"$out" || { echo "$out" >&2; fail "$script: sparse fetch not used"; }
    grep -q 'Коммит: stubsha' <<<"$out" || { echo "$out" >&2; fail "$script: commit not logged"; }
    grep -q '^ARGS:-a$' <<<"$out" || { echo "$out" >&2; fail "$script: clone path: args lost"; }
    pass "$script: sparse git clone installs verified bundle, no curl"

    echo edited > "$data/arch-multitool/modules/lib/multitool.sh"
    if ! out="$(PATH="$offlinebin:/usr/bin:/bin" HOME="$home" XDG_DATA_HOME="$data" \
        bash "$tmp/standalone/$script" -h 2>&1)"; then
        echo "$out" >&2; fail "$script: clone path: offline rerun failed"
    fi
    [[ "$(cat "$data/arch-multitool/modules/lib/multitool.sh")" == edited ]] || fail "$script: clone path: cache overwritten offline"
    pass "$script: clone path: rerun offline without git/curl"
    rm -rf "$tmp"
}

run_variant install.sh arch_multitool.sh pacman
run_variant install_debian.sh arch_multitool_debian.sh apt-get
run_clone_variant install.sh arch_multitool.sh pacman
run_clone_variant install_debian.sh arch_multitool_debian.sh apt-get

echo "ALL BOOTSTRAP TESTS PASSED"
