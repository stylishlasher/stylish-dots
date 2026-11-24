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

# Прямой запуск лаунчеров заменён плашкой; bootstrap помечает своё окружение.
run_noninteractive_test() {
    local out launcher rc
    for launcher in arch_multitool.sh arch_multitool_debian.sh; do
        set +e
        out="$(timeout 10 bash "$ROOT/$launcher" </dev/null 2>&1)"; rc=$?
        set -e
        [[ $rc -ne 0 ]] || fail "$launcher: direct launch succeeded"
        grep -q 'Прямой запуск мультитула отключён' <<<"$out" || { echo "$out" >&2; fail "$launcher: no bootstrap banner"; }
        grep -q 'install/install' <<<"$out" || { echo "$out" >&2; fail "$launcher: no bootstrap command in banner"; }
        [[ $(grep -c '== .* ==' <<<"$out") -eq 0 ]] || fail "$launcher: menu spam still present"
    done
    if out="$(printf '' | timeout 5 bash -c 't(){ echo "$1"; }; warn(){ echo "$*"; }; source "$1"; menu_select Title "0|Exit"' _ "$ROOT/modules/lib/menu.sh" 2>&1)"; then
        fail "menu_select accepted EOF"
    fi
    if out="$(printf '' | timeout 5 bash -c 't(){ echo "$1"; }; warn(){ echo "$*"; }; source "$1"; select_packages Title "pkg|desc|on"' _ "$ROOT/modules/lib/menu.sh" 2>&1)"; then
        fail "select_packages accepted EOF"
    fi
    pass "direct launchers show bootstrap banner; selectors exit on EOF"
}
run_noninteractive_test

# «Установка ПО → Neovim»: лёгкий и сложный пресеты выбираются в самом меню.
run_nvim_submenu_test() {
    local choice preset out
    for choice in 1 2; do
        preset=super-easy-casual; [[ "$choice" == 2 ]] && preset=lazyvim-stylish
        out="$(printf '%s\n' "$choice" | timeout 5 bash -c '
            require_module() { :; }
            t() { echo "$1"; }
            warn() { echo "$*"; }
            source "$1"; source "$2"
            action_install_neovim() { echo "INSTALL:$1"; }
            action_neovim_menu
        ' _ "$ROOT/modules/lib/menu.sh" "$ROOT/modules/actions/neovim.sh" 2>&1)"
        grep -q "INSTALL:$preset" <<<"$out" || { echo "$out" >&2; fail "nvim submenu: choice $choice did not install $preset"; }
    done
    pass "Neovim submenu installs old and new configs"
}
run_nvim_submenu_test

# Кэш удаляется только после подтверждения.
run_clear_cache_test() {
    local tmp out
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/stylish-cache-test.XXXXXX")"
    mkdir -p "$tmp/arch-multitool/releases/one" "$tmp/arch-multitool/current"
    echo payload > "$tmp/arch-multitool/releases/one/file"
    local stub='t(){ echo "$1"; }; warn(){ echo "$*"; }; ok(){ echo "$*"; }; is_interactive(){ return 0; }; source "$1"; source "$2"; action_clear_cache'
    out="$(XDG_DATA_HOME="$tmp" bash -c "confirm(){ return 1; }; $stub" _ "$ROOT/modules/lib/i18n.sh" "$ROOT/modules/actions/extras.sh" 2>&1 || true)"
    [[ -f "$tmp/arch-multitool/releases/one/file" ]] || { echo "$out" >&2; fail "clear cache: cancelled run deleted files"; }
    out="$(XDG_DATA_HOME="$tmp" bash -c "confirm(){ return 0; }; $stub" _ "$ROOT/modules/lib/i18n.sh" "$ROOT/modules/actions/extras.sh" 2>&1)"
    [[ ! -e "$tmp/arch-multitool/releases" && ! -e "$tmp/arch-multitool/current" ]] || { echo "$out" >&2; fail "clear cache: confirmed run left files"; }
    rm -rf "$tmp/arch-multitool"
    XDG_DATA_HOME="$tmp" bash -c "confirm(){ return 0; }; $stub" _ "$ROOT/modules/lib/i18n.sh" "$ROOT/modules/actions/extras.sh" >/dev/null 2>&1 || fail "clear cache: missing cache should be a no-op"
    rm -rf "$tmp"
    pass "cache deletion requires confirmation and is idempotent"
}
run_clear_cache_test

# Мастер установки передаёт имена пресетов, а не номера пунктов меню.
run_wizard_test() {
    local out
    out="$(printf '2\n9\n15\nd\n2\n6\n2\n' | timeout 10 bash -c '
        require_module(){ :; }
        t(){ echo "$1"; }
        info(){ :; }; warn(){ echo "$*"; }; err(){ echo "$*"; }; ok(){ echo "$*"; }
        is_interactive(){ return 1; }
        confirm(){ return 0; }
        action_preflight(){ :; }
        action_update_system(){ :; }
        action_install_basic(){ :; }
        pkg_install(){ :; }
        action_install_aur_helper(){ :; }
        action_install_sddm(){ :; }
        action_install_sddm_theme(){ echo "THEME:$1"; }
        action_install_fish(){ :; }
        action_build_rust_fetches(){ :; }
        action_install_flatpak(){ :; }
        action_install_warp(){ :; }
        action_configure_firewall(){ :; }
        action_install_bibata(){ :; }
        apply_bibata_theme(){ echo "CURSOR:$1"; }
        action_setup_monitors(){ :; }
        action_create_home_readme(){ :; }
        action_install_neovim(){ echo "NVIM:$1"; }
        action_install_fastfetch_preset(){ echo "FF:$1"; }
        action_install_caelestia(){ :; }
        action_apply_stylish(){ echo "PROFILE:stylish:$1"; }
        action_apply_end4(){ :; }
        action_install_dotfiles_profile(){ :; }
        source "$1"; source "$2"; action_full_interactive
    ' _ "$ROOT/modules/lib/menu.sh" "$ROOT/modules/actions/interactive.sh" 2>&1)"
    grep -q 'NVIM:super-easy-casual' <<<"$out" || { echo "$out" >&2; fail "wizard: wrong Neovim preset"; }
    grep -q 'PROFILE:stylish:super-easy-casual' <<<"$out" || { echo "$out" >&2; fail "wizard: profile got a menu number"; }
    grep -q 'CURSOR:Bibata-Modern-Ice' <<<"$out" || { echo "$out" >&2; fail "wizard: wrong cursor theme"; }
    grep -q 'THEME:stylish' <<<"$out" || { echo "$out" >&2; fail "wizard: SDDM theme does not match the dotfiles profile"; }
    ! grep -q 'NVIM:1' <<<"$out" || fail "wizard: numeric preset leaked into action"
    pass "wizard maps dotfiles profile, SDDM theme, Neovim preset and cursor by name"
}
run_wizard_test

# Авто-детект мониторов: X11 и Hyprland выбирают максимальную частоту.
run_monitors_test() {
    local tmp out
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/stylish-monitors-test.XXXXXX")"
    mkdir -p "$tmp/home"
    out="$(HOME="$tmp/home" bash -c '
        t(){ echo "$1"; }; info(){ :; }; warn(){ echo "$*"; }; ok(){ echo "$*"; }
        has(){ [[ "$1" == xrandr ]]; }
        xrandr(){
            if [[ "$1" == --current ]]; then
                printf "eDP-1 connected primary 1920x1080+0+0\n  1920x1080 60.00*+ 120.00 50.00\nHDMI-1 connected\n  1920x1080 144.00*+ 60.00\n"
            else echo "XRANDR:$*"; fi
        }
        source "$1"; action_setup_monitors
    ' _ "$ROOT/modules/actions/extras.sh" 2>&1)"
    grep -q 'XRANDR:--output HDMI-1 --mode 1920x1080 --rate 144.00' <<<"$out" || { echo "$out" >&2; fail "monitors: X11 did not pick 144 Hz"; }
    grep -q 'xrandr --output eDP-1 --mode 1920x1080 --rate 120.00' "$tmp/home/.xprofile" || fail "monitors: X11 settings not persisted"
    out="$(HOME="$tmp/home" bash -c '
        t(){ echo "$1"; }; info(){ :; }; warn(){ echo "$*"; }; ok(){ echo "$*"; }
        stash_dir(){ :; }
        has(){ [[ "$1" == hyprctl ]]; }
        hyprctl(){
            if [[ "$1 $2" == "monitors all" ]]; then printf "Monitor eDP-1 (ID 0):\n  availableModes: 1920x1080@60Hz 1920x1080@144Hz\n"
            elif [[ "$1" == monitors ]]; then return 0
            else echo "HYPR:$*"; fi
        }
        source "$1"; action_setup_monitors
    ' _ "$ROOT/modules/actions/extras.sh" 2>&1)"
    grep -q 'HYPR:keyword monitor eDP-1, highrr, auto, 1' <<<"$out" || { echo "$out" >&2; fail "monitors: Hyprland monitor not configured"; }
    grep -q 'monitor = eDP-1, highrr, auto, 1' "$tmp/home/.config/hypr/monitors.conf" || fail "monitors: Hyprland settings not persisted"
    rm -rf "$tmp"
    pass "monitor auto-detection applies maximum refresh on X11 and Hyprland"
}
run_monitors_test

# Четыре темы SDDM и замена картинки без root.
run_sddm_themes_test() {
    local tmp src out name before after
    src="$ROOT/config/sddm-themes"
    for name in caelestia end4 stylish serpantinum; do
        [[ -f "$src/$name/metadata.desktop" && -f "$src/$name/assets/avatar.png" && -f "$src/$name/assets/background.png" ]] || fail "sddm theme $name: missing files"
        [[ ! -e "$src/$name/assets/avatar.jpg" ]] || fail "sddm theme $name: default avatar still present"
        grep -q '"../../_assets/google-sans-flex/GoogleSansFlex.ttf"' "$src/$name/components/Greeting.qml" || fail "sddm theme $name: broken font path"
    done
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/stylish-sddm-test.XXXXXX")"
    out="$(HOME="$tmp/home" CONFIGS_DIR="$ROOT/config" bash -c '
        t(){ echo "$1"; }; stash_dir(){ :; }; ok(){ echo "$*"; }; warn(){ echo "$*"; }
        source "$1"; action_install_sddm_themes
    ' _ "$ROOT/modules/actions/extras.sh" 2>&1)"
    grep -q 'sddm_themes_ready' <<<"$out" || { echo "$out" >&2; fail "sddm themes: install failed"; }
    [[ -f "$tmp/home/.local/share/sddm/themes/end4/metadata.desktop" ]] || fail "sddm themes: not installed"
    before="$(sha256sum "$tmp/home/.local/share/sddm/themes/stylish/assets/avatar.png" | cut -d' ' -f1)"
    HOME="$tmp/home" bash "$src/set-image.sh" stylish avatar "$src/stylish/assets/background.png" >/dev/null || fail "set-image: failed"
    after="$(sha256sum "$tmp/home/.local/share/sddm/themes/stylish/assets/avatar.png" | cut -d' ' -f1)"
    [[ "$before" != "$after" ]] || fail "set-image: avatar unchanged"
    HOME="$tmp/home" bash "$src/set-image.sh" stylish background "$src/end4/assets/background.png" >/dev/null || fail "set-image: background failed"
    [[ -s "$tmp/home/.local/share/sddm/themes/stylish/assets/background.png" ]] || fail "set-image: empty background"
    grep -q 'PNG' <(file "$tmp/home/.local/share/sddm/themes/stylish/assets/background.png") || fail "set-image: background is not a PNG"
    rm -rf "$tmp/home/.local/share/sddm/themes"
    out="$(HOME="$tmp/home" CONFIGS_DIR="$ROOT/config" bash -c '
        t(){ echo "$1"; }; stash_dir(){ :; }; ok(){ echo "$*"; }; warn(){ echo "$*"; }
        source "$1"; action_install_sddm_theme end4
    ' _ "$ROOT/modules/actions/extras.sh" 2>&1)"
    grep -q 'sddm_theme_ready' <<<"$out" || { echo "$out" >&2; fail "single theme: install failed"; }
    [[ -f "$tmp/home/.local/share/sddm/themes/end4/metadata.desktop" ]] || fail "single theme: end4 not installed"
    [[ ! -e "$tmp/home/.local/share/sddm/themes/stylish" ]] || fail "single theme: installed unrelated themes"
    rm -rf "$tmp"
    pass "four SDDM themes install and accept a custom image"
}
run_sddm_themes_test

echo "ALL BOOTSTRAP TESTS PASSED"
