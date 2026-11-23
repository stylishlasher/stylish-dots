#!/usr/bin/env bash
# Тесты bootstrap: подпись, динамическая загрузка,Atomic swap, офлайн, откат, миграция.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "PASS: $*"; }

PUB=""

stub_launchers() {
    local dir="$1" f
    for f in arch_multitool.sh arch_multitool_debian.sh; do
        printf '#!/usr/bin/env bash\nprintf "ARGS:%%s\\n" "$*"\n' > "$dir/$f"
        chmod +x "$dir/$f"
    done
}

setup_test_key() {
    local dir="$1"
    openssl genrsa -out "$dir/test.key" 2048 2>/dev/null
    openssl rsa -in "$dir/test.key" -pubout -out "$dir/test.pub" 2>/dev/null
    PUB="$(cat "$dir/test.pub")"
}

# Установщик больше не принимает ключ из окружения: тесты подменяют его в своей копии.
patch_installer_pubkey() {
    local src="$1" dst="$2" pub="$3"
    awk -v pub="$pub" '
        /<<.*SD_PUBKEY/ { print; print pub; inkey = 1; next }
        inkey && /^SD_PUBKEY$/ { print; inkey = 0; next }
        inkey { next }
        { print }
    ' "$src" > "$dst"
    chmod +x "$dst"
}

# Манифест фикстуры повторяет формат scripts/sign-bundle.sh (включая исключения сборки).
sign_fixture() {
    local dir="$1" key="$2"
    (
        cd "$dir"
        {
            echo '# stylish-dots bundle v2'
            find arch_multitool.sh arch_multitool_debian.sh modules config -path '*/target' -prune -o -path '*__pycache__' -prune -o -type f -printf '# mode %m %p\n' | LC_ALL=C sort
            find arch_multitool.sh arch_multitool_debian.sh modules config -path '*/target' -prune -o -path '*__pycache__' -prune -o -type l -printf '# link %p -> %l\n' | LC_ALL=C sort
            find arch_multitool.sh arch_multitool_debian.sh modules config -path '*/target' -prune -o -path '*__pycache__' -prune -o -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum
        } > bundle.sha256
    )
    openssl dgst -sha256 -sign "$key" -out "$dir/bundle.sha256.sig" "$dir/bundle.sha256"
}

make_payload() {
    local dir="$1" m
    mkdir -p "$dir/modules/lib" "$dir/config/fastfetch" "$dir/config/end4"
    stub_launchers "$dir"
    for m in multitool i18n common; do echo marker > "$dir/modules/lib/$m.sh"; done
    echo preset > "$dir/config/fastfetch/config.jsonc"
    ln -s ../fastfetch/config.jsonc "$dir/config/end4/link.jsonc"
}

# PATH только с разрешёнными утилитами; git/curl/sudo подменены и оставляют метку.
make_offline_bin() {
    local dir="$1" marker="$2" tool
    mkdir -p "$dir"
    for tool in bash cat cp date dirname find grep ln mkdir mktemp mv openssl readlink rm rmdir sha256sum sort stat tail tar uname wc; do
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
    local -a E EO
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/stylish-bootstrap-test.XXXXXX")"
    repo="$tmp/repo"; home="$tmp/home"; data="$home/.local/share"; offlinebin="$tmp/offlinebin"
    marker="$tmp/NETWORK_USED"; current="$data/arch-multitool/current"
    setup_test_key "$tmp"
    E=(env "PATH=$tmp/bin:$PATH" HOME="$home" XDG_DATA_HOME="$data")
    EO=(env PATH="$offlinebin" HOME="$home" XDG_DATA_HOME="$data")

    mkdir -p "$repo/install" "$tmp/bin"
    patch_installer_pubkey "$ROOT/install/$script" "$repo/install/$script" "$PUB"
    make_payload "$repo"
    mkdir -p "$repo/config/fetches/stylish-fetches/target" "$repo/config/bin/__pycache__"
    echo artifact > "$repo/config/fetches/stylish-fetches/target/keyfetch"
    echo artifact > "$repo/config/bin/__pycache__/x.pyc"
    sign_fixture "$repo" "$tmp/test.key"
    printf '#!/usr/bin/env bash\nexit 0\n' > "$tmp/bin/$pkg"
    make_offline_bin "$offlinebin" "$marker"

    local out
    if ! out="$("${E[@]}" bash "$repo/install/$script" -a --refresh 2>&1)"; then
        echo "$out" >&2; fail "$script: first run failed"
    fi
    [[ -L "$current" ]] || fail "$script: current is not a symlink"
    [[ "$(readlink "$current")" == releases/* ]] || fail "$script: current does not point to a release"
    [[ -x "$current/$launcher" ]] || fail "$script: launcher not installed"
    [[ -f "$current/modules/lib/multitool.sh" ]] || fail "$script: modules cache missing"
    [[ -f "$current/config/fastfetch/config.jsonc" ]] || fail "$script: config cache missing"
    grep -q '^ARGS:-a$' <<<"$out" || { echo "$out" >&2; fail "$script: --refresh leaked to multitool"; }
    pass "$script: installs signed launcher + modules + config in a release"
    [[ ! -e "$current/config/fetches/stylish-fetches/target" ]] || fail "$script: build artifacts in cache"
    [[ ! -e "$current/config/bin/__pycache__" ]] || fail "$script: __pycache__ in cache"
    pass "$script: build artifacts excluded"

    if ! out="$("${EO[@]}" bash "$repo/install/$script" -h 2>&1)"; then
        echo "$out" >&2; fail "$script: offline run failed"
    fi
    assert_no_network "$marker" "$script offline"
    grep -q 'Набор проверен' <<<"$out" || { echo "$out" >&2; fail "$script: verify message missing"; }
    pass "$script: offline run with only whitelisted binaries"

    # Ключ нельзя подменить через окружение: установщик обязан использовать вшитый.
    if ! out="$(env STYLISH_BUNDLE_PUBKEY='not-a-pem' PATH="$offlinebin" HOME="$home" XDG_DATA_HOME="$data" \
        bash "$repo/install/$script" -h 2>&1)"; then
        echo "$out" >&2; fail "$script: environment overrode the embedded key"
    fi
    pass "$script: STYLISH_BUNDLE_PUBKEY in env is ignored"

    # Битый модуль, подменённый конфиг, права и симлинк чинятся без --refresh.
    printf 'if [[ ' > "$current/modules/lib/i18n.sh"
    echo tampered > "$current/config/fastfetch/config.jsonc"
    chmod 600 "$current/modules/lib/common.sh"
    rm "$current/config/end4/link.jsonc"
    ln -s /nowhere "$current/config/end4/link.jsonc"
    if ! out="$("${EO[@]}" bash "$repo/install/$script" -h 2>&1)"; then
        echo "$out" >&2; fail "$script: tampered cache not repaired"
    fi
    assert_no_network "$marker" "$script cache repair"
    [[ "$(cat "$current/modules/lib/i18n.sh")" == marker ]] || fail "$script: broken module not repaired"
    [[ "$(cat "$current/config/fastfetch/config.jsonc")" == preset ]] || fail "$script: config content not restored"
    [[ "$(stat -c %a "$current/modules/lib/common.sh")" == 644 ]] || fail "$script: mode not restored"
    [[ "$(readlink "$current/config/end4/link.jsonc")" == ../fastfetch/config.jsonc ]] || fail "$script: symlink not restored"
    pass "$script: manifest repairs content, permissions and symlinks offline"

    # Подмена и манифеста, и подписи чужим ключом не принимается.
    echo '# tampered' >> "$current/bundle.sha256"
    openssl genrsa -out "$tmp/wrong.key" 2048 2>/dev/null
    openssl dgst -sha256 -sign "$tmp/wrong.key" -out "$current/bundle.sha256.sig" "$current/bundle.sha256"
    if ! out="$("${EO[@]}" bash "$repo/install/$script" -h 2>&1)"; then
        echo "$out" >&2; fail "$script: foreign signature not rejected"
    fi
    assert_no_network "$marker" "$script signature repair"
    if [[ "$(tail -1 "$current/bundle.sha256")" == '# tampered' ]]; then
        fail "$script: forged manifest survived"
    fi
    pass "$script: manifest+signature replaced by a foreign key is rejected"

    local before
    before="$(readlink "$current")"
    "${E[@]}" bash "$repo/install/$script" --refresh >/dev/null 2>&1 || fail "$script: refresh failed"
    [[ "$(cat "$current/modules/lib/multitool.sh")" == marker ]] || fail "$script: --refresh did not refresh cache"
    [[ "$(readlink "$current")" != "$before" ]] || fail "$script: --refresh did not switch release"
    local -a rels=()
    mapfile -t rels < <(find "$data/arch-multitool/releases" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
    [[ ${#rels[@]} -ge 2 ]] || fail "$script: previous release removed, no rollback possible"
    pass "$script: --refresh re-copies cache and keeps previous release"

    before="$(readlink "$current")"
    rm -f "$repo/modules/lib/i18n.sh"
    if "${E[@]}" bash "$repo/install/$script" --refresh >/dev/null 2>&1; then
        fail "$script: broken bundle was accepted"
    fi
    [[ "$(readlink "$current")" == "$before" ]] || fail "$script: broken refresh moved current"
    [[ -f "$current/modules/lib/i18n.sh" ]] || fail "$script: bad refresh destroyed the cache"
    echo marker > "$repo/modules/lib/i18n.sh"
    sign_fixture "$repo" "$tmp/test.key"
    pass "$script: broken bundle rejected, current unchanged"

    printf 'if [[ ' > "$repo/$launcher"
    if "${E[@]}" bash "$repo/install/$script" --refresh >/dev/null 2>&1; then
        fail "$script: broken launcher was accepted"
    fi
    [[ "$(readlink "$current")" == "$before" ]] || fail "$script: broken launcher moved current"
    stub_launchers "$repo"
    sign_fixture "$repo" "$tmp/test.key"
    if ! out="$("${EO[@]}" bash "$repo/install/$script" -a 2>&1)"; then
        echo "$out" >&2; fail "$script: launcher not restored"
    fi
    grep -q '^ARGS:-a$' <<<"$out" || { echo "$out" >&2; fail "$script: restored launcher broken"; }
    pass "$script: broken launcher rejected, current unchanged"

    # Отказ самого rename не должен сдвинуть current.
    cat > "$tmp/bin/mv" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "-Tf" ]]; then echo SWITCH_FAILED >&2; exit 7; fi
exec /usr/bin/mv "$@"
EOF
    chmod +x "$tmp/bin/mv"
    before="$(readlink "$current")"
    if "${E[@]}" bash "$repo/install/$script" --refresh >/dev/null 2>&1; then
        fail "$script: switch failure was ignored"
    fi
    [[ "$(readlink "$current")" == "$before" ]] || fail "$script: failed switch moved current"
    [[ -x "$current/$launcher" ]] || fail "$script: failed switch broke launcher"
    pass "$script: failed rename rolls back to previous release"

    # Ссылка уже переключилась, но проверка нового релиза провалилась -> откат.
    cat > "$tmp/bin/mv" <<EOF
#!/usr/bin/env bash
if [[ "\${1:-}" == "-Tf" ]]; then
    dest="\${@: -1}"
    /usr/bin/mv "\$@" || exit \$?
    target="\$(dirname "\$dest")/\$(readlink "\$dest")"
    printf 'if [[ ' > "\$target/$launcher"
    exit 0
fi
exec /usr/bin/mv "\$@"
EOF
    chmod +x "$tmp/bin/mv"
    before="$(readlink "$current")"
    local -a rels_before=() rels_after=()
    mapfile -t rels_before < <(find "$data/arch-multitool/releases" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
    if "${E[@]}" bash "$repo/install/$script" --refresh >/dev/null 2>&1; then
        fail "$script: post-switch verification failure was ignored"
    fi
    [[ "$(readlink "$current")" == "$before" ]] || fail "$script: post-switch failure kept broken current"
    mapfile -t rels_after < <(find "$data/arch-multitool/releases" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
    [[ ${#rels_after[@]} -eq ${#rels_before[@]} ]] || fail "$script: broken release not removed on rollback"
    if ! out="$("${EO[@]}" bash "$repo/install/$script" -a 2>&1)"; then
        echo "$out" >&2; fail "$script: rollback left unusable bundle"
    fi
    grep -q '^ARGS:-a$' <<<"$out" || { echo "$out" >&2; fail "$script: rollback launcher broken"; }
    pass "$script: failed post-switch verify rolls back to previous release"
    rm -rf "$tmp"
}

# Сетевой путь: локального репо нет, всё приходит через sparse git clone.
run_clone_variant() {
    local script="$1" launcher="$2" pkg="$3"
    local tmp fixture home data offlinebin marker current
    local -a E EO
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/stylish-clone-test.XXXXXX")"
    fixture="$tmp/fixture"; home="$tmp/home"; data="$home/.local/share"; offlinebin="$tmp/offlinebin"
    marker="$tmp/NETWORK_USED"; current="$data/arch-multitool/current"
    setup_test_key "$tmp"
    E=(env "PATH=$tmp/bin:$PATH" HOME="$home" XDG_DATA_HOME="$data")
    EO=(env PATH="$offlinebin" HOME="$home" XDG_DATA_HOME="$data")
    mkdir -p "$tmp/bin" "$tmp/standalone"
    make_payload "$fixture"
    sign_fixture "$fixture" "$tmp/test.key"
    patch_installer_pubkey "$ROOT/install/$script" "$tmp/standalone/$script" "$PUB"
    printf '#!/usr/bin/env bash\nexit 0\n' > "$tmp/bin/$pkg"
    make_offline_bin "$offlinebin" "$marker"

    cat > "$tmp/bin/git" <<EOF
#!/usr/bin/env bash
if [[ "\${1:-}" == "clone" ]]; then
    [[ " \$* " == *" --filter=blob:none "* ]] || { echo NO_FILTER >&2; exit 3; }
    [[ " \$* " == *" --sparse "* ]] || { echo NO_SPARSE >&2; exit 3; }
    dest="\${@: -1}"
    mkdir -p "\$dest"
    cp -a "$fixture/." "\$dest/"
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
    chmod +x "$tmp/bin/git"

    local out
    if ! out="$("${E[@]}" bash "$tmp/standalone/$script" -a 2>&1)"; then
        echo "$out" >&2; fail "$script: clone path failed"
    fi
    [[ -L "$current" ]] || fail "$script: clone path: current is not a symlink"
    [[ -f "$current/$launcher" ]] || fail "$script: clone path: launcher missing"
    [[ -f "$current/bundle.sha256.sig" ]] || fail "$script: clone path: signature missing"
    [[ -f "$current/modules/lib/i18n.sh" ]] || fail "$script: clone path: modules missing"
    [[ -f "$current/config/fastfetch/config.jsonc" ]] || fail "$script: clone path: config missing"
    grep -q 'только нужные пути' <<<"$out" || { echo "$out" >&2; fail "$script: sparse fetch not used"; }
    grep -q 'Коммит: stubsha' <<<"$out" || { echo "$out" >&2; fail "$script: commit not logged"; }
    grep -q '^ARGS:-a$' <<<"$out" || { echo "$out" >&2; fail "$script: clone path: args lost"; }
    pass "$script: sparse git clone installs verified bundle"

    if ! out="$("${EO[@]}" bash "$tmp/standalone/$script" -h 2>&1)"; then
        echo "$out" >&2; fail "$script: clone path: offline rerun failed"
    fi
    assert_no_network "$marker" "$script clone offline"
    grep -q 'Набор проверен' <<<"$out" || { echo "$out" >&2; fail "$script: clone path: cache not verified"; }
    ! grep -q 'Скачиваю' <<<"$out" || { echo "$out" >&2; fail "$script: clone path: refetched offline"; }
    [[ "$(cat "$current/modules/lib/multitool.sh")" == marker ]] || fail "$script: clone path: cache changed offline"
    pass "$script: clone path: rerun offline without git/curl"
    rm -rf "$tmp"
}

# Переход со старой структуры (файлы в корне INSTALL_DIR) на current/releases.
run_migration_variant() {
    local script="$1" launcher="$2" pkg="$3"
    local tmp repo home data old
    local -a E
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/stylish-migration-test.XXXXXX")"
    repo="$tmp/repo"; home="$tmp/home"; data="$home/.local/share"; old="$data/arch-multitool"
    setup_test_key "$tmp"
    E=(env "PATH=$tmp/bin:$PATH" HOME="$home" XDG_DATA_HOME="$data")
    mkdir -p "$repo/install" "$old/modules/lib" "$old/config/fastfetch" "$tmp/bin"
    patch_installer_pubkey "$ROOT/install/$script" "$repo/install/$script" "$PUB"
    make_payload "$repo"
    sign_fixture "$repo" "$tmp/test.key"
    printf '#!/usr/bin/env bash\nexit 0\n' > "$tmp/bin/$pkg"

    # Состояние пользователя после установки старой версии bootstrap.
    stub_launchers "$old"
    echo legacy > "$old/modules/lib/multitool.sh"
    echo legacy > "$old/config/fastfetch/config.jsonc"
    [[ ! -e "$old/current" ]] || fail "$script: migration fixture already has current"

    local out
    if ! out="$("${E[@]}" bash "$repo/install/$script" -a 2>&1)"; then
        echo "$out" >&2; fail "$script: migration failed"
    fi
    [[ -L "$old/current" ]] || fail "$script: migration did not create current symlink"
    [[ "$(readlink "$old/current")" == releases/* ]] || fail "$script: migration symlink target wrong"
    [[ "$(cat "$old/current/modules/lib/multitool.sh")" == marker ]] || fail "$script: migration kept stale modules"
    [[ "$(cat "$old/current/config/fastfetch/config.jsonc")" == preset ]] || fail "$script: migration kept stale config"
    grep -q '^ARGS:-a$' <<<"$out" || { echo "$out" >&2; fail "$script: migration args lost"; }
    # Старые файлы не удаляются: миграция не разрушает пользовательские данные.
    [[ "$(cat "$old/modules/lib/multitool.sh")" == legacy ]] || fail "$script: migration removed old modules"
    [[ "$(cat "$old/config/fastfetch/config.jsonc")" == legacy ]] || fail "$script: migration removed old config"
    pass "$script: migrates old layout without deleting user files"
    rm -rf "$tmp"
}

# Реальный репозиторий: вшитый публичный ключ проверяет закоммиченную подпись.
run_real_repo_test() {
    local tmp home data offlinebin marker out
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/stylish-real-test.XXXXXX")"
    home="$tmp/home"; data="$home/.local/share"; offlinebin="$tmp/offlinebin"; marker="$tmp/NETWORK_USED"
    mkdir -p "$tmp/bin"
    printf '#!/usr/bin/env bash\nexit 0\n' > "$tmp/bin/pacman"
    make_offline_bin "$offlinebin" "$marker"
    if ! out="$(env PATH="$tmp/bin:$PATH" HOME="$home" XDG_DATA_HOME="$data" \
        bash "$ROOT/install/install.sh" --help 2>&1)"; then
        echo "$out" >&2; fail "real repo: embedded public key rejected committed signature"
    fi
    if ! out="$(env PATH="$offlinebin" HOME="$home" XDG_DATA_HOME="$data" \
        bash "$ROOT/install/install.sh" --help 2>&1)"; then
        echo "$out" >&2; fail "real repo: offline verification failed"
    fi
    assert_no_network "$marker" "real repo offline"
    grep -q 'Набор проверен' <<<"$out" || { echo "$out" >&2; fail "real repo: cache not verified"; }
    grep -q 'Модули:' <<<"$out" || { echo "$out" >&2; fail "real repo: launcher did not start"; }
    pass "real repo installs with embedded key and verifies offline"
    rm -rf "$tmp"
}

run_variant install.sh arch_multitool.sh pacman
run_variant install_debian.sh arch_multitool_debian.sh apt-get
run_clone_variant install.sh arch_multitool.sh pacman
run_clone_variant install_debian.sh arch_multitool_debian.sh apt-get
run_migration_variant install.sh arch_multitool.sh pacman
run_migration_variant install_debian.sh arch_multitool_debian.sh apt-get
run_real_repo_test

echo "ALL BOOTSTRAP TESTS PASSED"
