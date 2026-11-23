#!/usr/bin/env bash
# Регрессионные тесты backup/restore/stash. Запуск: bash tests/backup-tests.sh
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
export STYLISH_LANG=ru # тесты проверяют исходные сообщения

fail() { echo "FAIL: $*" >&2; [[ -f "${TMP:-}/out" ]] && { echo "--- output ---"; cat "${TMP}/out"; }; exit 1; }
pass() { echo "PASS: $*"; }

fresh() {
    unset -f cp backup_register 2>/dev/null || true
    TMP=$(mktemp -d)
    HOME="$TMP/home"; mkdir -p "$HOME"
    export HOME XDG_STATE_HOME="$HOME/.local/state"
    source modules/lib/common.sh
    source modules/actions/backup.sh
}

# 1. legacy import: ошибка backup_register -> warn, импорт продолжается
fresh
mkdir -p "$HOME/.config-backup-end4-1/hypr/custom"
echo x > "$HOME/.config-backup-end4-1/hypr/custom/a.conf"
backup_register() { return 1; }
set +e; backup_import_legacy >"$TMP/out" 2>&1; rc=$?; set -e
[[ $rc -eq 0 ]] || fail "legacy import rc=$rc"
grep -q "Не удалось зарегистрировать legacy backup" "$TMP/out" || fail "no warning"
pass "legacy import tolerates register failure"

# 2. restore: cp падает с частичным target -> прежнее состояние возвращено
fresh
mkdir -p "$HOME/.config/fish" "$TMP/bk/fish"
echo old > "$TMP/bk/fish/config.fish"
echo new > "$HOME/.config/fish/config.fish"
backup_register "$HOME/.config/fish" "$TMP/bk/fish" >/dev/null
cp() {
    if [[ "$1" == "-a" && "$2" == "$TMP/bk/fish" ]]; then
        mkdir -p "$3"; echo partial > "$3/config.fish"; return 1
    fi
    command cp "$@"
}
set +e; action_restore_backup "$HOME/.config/fish" >"$TMP/out" 2>&1; rc=$?; set -e
[[ $rc -ne 0 ]] || fail "restore should fail"
[[ "$(cat "$HOME/.config/fish/config.fish")" == "new" ]] || fail "state not restored"
grep -Fq "Возвращено прежнее состояние" "$TMP/out" || fail "missing rollback message"
pass "restore rollback on cp failure"

# 3. restore: ошибка записи в реестр -> текущее состояние возвращено
fresh
mkdir -p "$HOME/.config/fish" "$TMP/bk/fish"
echo old > "$TMP/bk/fish/config.fish"
echo new > "$HOME/.config/fish/config.fish"
backup_register "$HOME/.config/fish" "$TMP/bk/fish" >/dev/null
backup_register() { return 1; }
set +e; action_restore_backup "$HOME/.config/fish" >"$TMP/out" 2>&1; rc=$?; set -e
[[ $rc -ne 0 ]] || fail "should fail"
[[ "$(cat "$HOME/.config/fish/config.fish")" == "new" ]] || fail "not rolled back"
pass "registry failure rollback"

# 4. stash_dir: mv прошёл, реестр не записан -> файл возвращён на место
fresh
mkdir -p "$HOME/.config/fish"
echo keep > "$HOME/.config/fish/config.fish"
backup_register() { return 1; }
set +e; stash_dir "$HOME/.config/fish" >"$TMP/out" 2>&1; rc=$?; set -e
[[ $rc -ne 0 ]] || fail "stash should fail"
[[ "$(cat "$HOME/.config/fish/config.fish")" == "keep" ]] || fail "file not returned"
pass "stash_dir rollback on registry failure"

# 5. restore: успех через mktemp, чужой файл по старому предсказуемому пути не тронут
fresh
mkdir -p "$HOME/.config/fish" "$TMP/bk/fish"
echo old > "$TMP/bk/fish/config.fish"
echo new > "$HOME/.config/fish/config.fish"
backup_register "$HOME/.config/fish" "$TMP/bk/fish" >/dev/null
echo do-not-touch > "$HOME/.config/fish.restore-tmp.99999"
set +e; action_restore_backup "$HOME/.config/fish" >"$TMP/out" 2>&1; rc=$?; set -e
[[ $rc -eq 0 ]] || fail "restore should succeed"
[[ "$(cat "$HOME/.config/fish/config.fish")" == "old" ]] || fail "backup not restored"
[[ "$(cat "$HOME/.config/fish.restore-tmp.99999")" == "do-not-touch" ]] || fail "decoy file touched"
[[ -f "$TMP/bk/fish/config.fish" ]] || fail "original backup removed"
pass "restore via mktemp keeps unrelated files"

# 6. чистая система: restore_profile без реестра не падает
fresh
set +e; action_restore_profile stylish </dev/null >"$TMP/out" 2>&1; rc=$?; set -e
[[ $rc -eq 0 ]] || fail "clean rollback rc=$rc"
[[ -f "$HOME/.local/state/stylish-dots/backups.tsv" ]] || fail "registry not created"
pass "clean system rollback"

echo "ALL TESTS PASSED"