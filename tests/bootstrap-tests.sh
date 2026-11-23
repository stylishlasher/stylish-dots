#!/usr/bin/env bash
# Тесты bootstrap: динамическая загрузка, полная проверка, атомарное переключение, офлайн, откат.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "PASS: $*"; }

stub_launcher() {
    printf '#!/usr/bin/env bash\nprintf "ARGS:%%s\\n" "$*"\n' > "$1"
}

# PATH только с разрешёнными утилитами; git/curl/sudo подменены и оставляют метку.
make_offline_bin() {
    local dir="$1" marker="$2" tool
    mkdir -p "$dir"
    for tool in bash cat chmod cp date dirname find ln mkdir mktemp mv readlink rm rmdir tar uname; do
        ln -s "$(command -v "$tool")" "$dir/$tool"
    done
    for tool in pacman apt-get; do
        printf '#!/usr/bin/env bash\nexit 0\n' > "$dir/$tool"
        chmod +x "$dir/$tool"
    done
    for tool in git curl sudo; do
        printf '#!/usr/bin/env bash\necho used > "%s"\nexit 9\n' "$marker" > "$dir/$tool"
        chmod +x "$dir/$tool"
    done
}

assert_no_network() {
    local marker="$1" where="$2"
    [[ ! -e "$marker" ]] || fail "$where: git/curl/sudo were used"
}

run_variant() {
    local script="$1" launcher="$2" pkg="$3"
    local tmp repo home data offlinebin marker current
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/stylish-bootstrap-test.XXXXXX")"
    repo="$tmp/repo"; home="$tmp/home"; data="$home/.local/share"; offlinebin="$tmp/offlinebin"
    marker="$tmp/NETWORK_USED"; current="$data/arch-multitool/current"
    mkdir -p "$repo/install" "$repo/modules/lib" "$repo/config/fastfetch" "$tmp/bin"
    cp "$ROOT/install/$script" "$repo/install/$script"
    stub_launcher "$repo/$launcher"
    for m in multitool i18n common; do echo marker > "$repo/modules/lib/$m.sh"; done
    mkdir -p "$repo/config/end4"
    echo preset > "$repo/config/fastfetch/config.jsonc"
    mkdir -p "$repo/config/fetches/stylish-fetches/target" "$repo/config/bin/__pycache__"
    echo artifact > "$repo/config/fetches/stylish-fetches/target/keyfetch"
    echo artifact > "$repo/config/bin/__pycache__/x.pyc"
    printf '#!/usr/bin/env bash\nexit 0\n' > "$tmp/bin/$pkg"
    make_offline_bin "$offlinebin" "$marker"

    local out
    if ! out="$(PATH="$tmp/bin:$PATH" HOME="$home" XDG_DATA_HOME="$data" \
        bash "$repo/install/$script" -a --refresh 2>&1)"; then
        echo "$out" >&2; fail "$script: first run failed"
    fi
    [[ -L "$current" ]] || fail "$script: current is not a symlink"
    [[ "$(readlink "$current")" == releases/* ]] || fail "$script: current does not point to a release"
    [[ -x "$current/$launcher" ]] || fail "$script: launcher not installed"
    [[ -f "$current/modules/lib/multitool.sh" ]] || fail "$script: modules cache missing"
    [[ -f "$current/config/fastfetch/config.jsonc" ]] || fail "$script: config cache missing"
    grep -q '^ARGS:-a$' <<<"$out" || { echo "$out" >&2; fail "$script: --refresh leaked to multitool"; }
    pass "$script: installs launcher + modules + config in a release"
    [[ ! -e "$current/config/fetches/stylish-fetches/target" ]] || fail "$script: build artifacts in cache"
    [[ ! -e "$current/config/bin/__pycache__" ]] || fail "$script: __pycache__ in cache"
    pass "$script: build artifacts excluded"

    if ! out="$(PATH="$offlinebin" HOME="$home" XDG_DATA_HOME="$data" \
        bash "$repo/install/$script" -h 2>&1)"; then
        echo "$out" >&2; fail "$script: offline run failed"
    fi
    assert_no_network "$marker" "$script offline"
    grep -q 'Набор проверен' <<<"$out" || { echo "$out" >&2; fail "$script: verify message missing"; }
    pass "$script: offline run with only whitelisted binaries"

    # П.3: существующий набор проверяется целиком, битый модуль починится без --refresh.
    printf 'if [[ ' > "$current/modules/lib/i18n.sh"
    if ! out="$(PATH="$offlinebin" HOME="$home" XDG_DATA_HOME="$data" \
        bash "$repo/install/$script" -h 2>&1)"; then
        echo "$out" >&2; fail "$script: broken cached module not repaired"
    fi
    assert_no_network "$marker" "$script cache repair"
    [[ "$(cat "$current/modules/lib/i18n.sh")" == marker ]] || fail "$script: broken module not repaired"
    pass "$script: full verify_bundle on cached run repairs broken module"

    local before
    before="$(readlink "$current")"
    PATH="$tmp/bin:$PATH" HOME="$home" XDG_DATA_HOME="$data" \
        bash "$repo/install/$script" --refresh >/dev/null 2>&1 || fail "$script: refresh failed"
    [[ "$(cat "$current/modules/lib/multitool.sh")" == marker ]] || fail "$script: --refresh did not refresh cache"
    [[ "$(readlink "$current")" != "$before" ]] || fail "$script: --refresh did not switch release"
    local -a rels=()
    mapfile -t rels < <(find "$data/arch-multitool/releases" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
    [[ ${#rels[@]} -ge 2 ]] || fail "$script: previous release removed, no rollback possible"
    pass "$script: --refresh re-copies cache and keeps previous release"

    before="$(readlink "$current")"
    rm -f "$repo/modules/lib/i18n.sh"
    if PATH="$tmp/bin:$PATH" HOME="$home" XDG_DATA_HOME="$data" \
        bash "$repo/install/$script" --refresh >/dev/null 2>&1; then
        fail "$script: broken bundle was accepted"
    fi
    [[ "$(readlink "$current")" == "$before" ]] || fail "$script: broken refresh moved current"
    [[ -f "$current/modules/lib/i18n.sh" ]] || fail "$script: bad refresh destroyed the cache"
    pass "$script: broken bundle rejected, current unchanged"
    echo marker > "$repo/modules/lib/i18n.sh"

    printf 'if [[ ' > "$repo/$launcher"
    if PATH="$tmp/bin:$PATH" HOME="$home" XDG_DATA_HOME="$data" \
        bash "$repo/install/$script" --refresh >/dev/null 2>&1; then
        fail "$script: broken launcher was accepted"
    fi
    [[ "$(readlink "$current")" == "$before" ]] || fail "$script: broken launcher moved current"
    if ! out="$(PATH="$offlinebin" HOME="$home" XDG_DATA_HOME="$data" \
        bash "$repo/install/$script" -a 2>&1)"; then
        echo "$out" >&2; fail "$script: launcher not restored"
    fi
    grep -q '^ARGS:-a$' <<<"$out" || { echo "$out" >&2; fail "$script: restored launcher broken"; }
    pass "$script: broken launcher rejected, current unchanged"

    # П.1: отказ на единственном rename не должен сдвинуть current.
    cat > "$tmp/bin/mv" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "-Tf" ]]; then echo SWITCH_FAILED >&2; exit 7; fi
exec /usr/bin/mv "$@"
EOF
    chmod +x "$tmp/bin/mv"
    before="$(readlink "$current")"
    if PATH="$tmp/bin:$PATH" HOME="$home" XDG_DATA_HOME="$data" \
        bash "$repo/install/$script" --refresh >/dev/null 2>&1; then
        fail "$script: switch failure was ignored"
    fi
    [[ "$(readlink "$current")" == "$before" ]] || fail "$script: failed switch moved current"
    [[ -x "$current/$launcher" ]] || fail "$script: failed switch broke launcher"
    pass "$script: failed rename rolls back to previous release"
    rm -f "$tmp/bin/mv"
    rm -rf "$tmp"
}

# Сетевой путь: локального репо нет, всё приходит через sparse git clone.
run_clone_variant() {
    local script="$1" launcher="$2" pkg="$3"
    local tmp fixture home data offlinebin marker current
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/stylish-clone-test.XXXXXX")"
    fixture="$tmp/fixture"; home="$tmp/home"; data="$home/.local/share"; offlinebin="$tmp/offlinebin"
    marker="$tmp/NETWORK_USED"; current="$data/arch-multitool/current"
    mkdir -p "$fixture/modules/lib" "$fixture/config/fastfetch" "$fixture/config/end4" \
        "$tmp/bin" "$offlinebin" "$tmp/standalone"
    for m in multitool i18n common; do echo marker > "$fixture/modules/lib/$m.sh"; done
    echo preset > "$fixture/config/fastfetch/config.jsonc"
    stub_launcher "$fixture/$launcher"
    cp "$ROOT/install/$script" "$tmp/standalone/$script"
    printf '#!/usr/bin/env bash\nexit 0\n' > "$tmp/bin/$pkg"
    make_offline_bin "$offlinebin" "$marker"

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
    chmod +x "$tmp/bin/git" "$tmp/bin/$pkg"

    local out
    if ! out="$(PATH="$tmp/bin:$PATH" HOME="$home" XDG_DATA_HOME="$data" \
        bash "$tmp/standalone/$script" -a 2>&1)"; then
        echo "$out" >&2; fail "$script: clone path failed"
    fi
    [[ -L "$current" ]] || fail "$script: clone path: current is not a symlink"
    [[ -f "$current/$launcher" ]] || fail "$script: clone path: launcher missing"
    [[ -f "$current/modules/lib/i18n.sh" ]] || fail "$script: clone path: modules missing"
    [[ -f "$current/config/fastfetch/config.jsonc" ]] || fail "$script: clone path: config missing"
    grep -q 'только нужные пути' <<<"$out" || { echo "$out" >&2; fail "$script: sparse fetch not used"; }
    grep -q 'Коммит: stubsha' <<<"$out" || { echo "$out" >&2; fail "$script: commit not logged"; }
    grep -q '^ARGS:-a$' <<<"$out" || { echo "$out" >&2; fail "$script: clone path: args lost"; }
    pass "$script: sparse git clone installs verified bundle"

    echo edited > "$current/modules/lib/multitool.sh"
    if ! out="$(PATH="$offlinebin" HOME="$home" XDG_DATA_HOME="$data" \
        bash "$tmp/standalone/$script" -h 2>&1)"; then
        echo "$out" >&2; fail "$script: clone path: offline rerun failed"
    fi
    assert_no_network "$marker" "$script clone offline"
    [[ "$(cat "$current/modules/lib/multitool.sh")" == edited ]] || fail "$script: clone path: cache overwritten offline"
    pass "$script: clone path: rerun offline without git/curl"
    rm -rf "$tmp"
}

run_variant install.sh arch_multitool.sh pacman
run_variant install_debian.sh arch_multitool_debian.sh apt-get
run_clone_variant install.sh arch_multitool.sh pacman
run_clone_variant install_debian.sh arch_multitool_debian.sh apt-get

echo "ALL BOOTSTRAP TESTS PASSED"
