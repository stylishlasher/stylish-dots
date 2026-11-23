#!/usr/bin/env bash
# Регрессионные тесты backup/restore/stash. Запуск: bash tests/backup-tests.sh
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
export STYLISH_LANG=ru # тесты проверяют исходные сообщения

fail() { echo "FAIL: $*" >&2; [[ -f "${TMP:-}/out" ]] && { echo "--- output ---"; cat "${TMP}/out"; }; exit 1; }
pass() { echo "PASS: $*"; }

fresh() {
    unset -f cp backup_register date 2>/dev/null || true
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

# 7. секундная Collision: два stash подряд с одним и тем же timestamps дают разные имена.
fresh
date() { [[ "$1" == '+%Y%m%d_%H%M%S_%N' ]] && { echo 20260101_000000_000000000; return; }; command date "$@"; }
mkdir -p "$HOME/.config/fish"
echo one > "$HOME/.config/fish/config.fish"
stash_dir "$HOME/.config/fish" >/dev/null
mkdir -p "$HOME/.config/fish"
echo two > "$HOME/.config/fish/config.fish"
stash_dir "$HOME/.config/fish" >/dev/null
mapfile -t made < <(find "$HOME/.config" -maxdepth 1 -name 'fish.bak.*' -print | sort)
[[ ${#made[@]} -eq 2 ]] || fail "expected 2 distinct backups, got ${#made[@]}"
[[ "$(cat "${made[0]}/config.fish")" == one && "$(cat "${made[1]}/config.fish")" == two ]] || fail "backup content overwritten"
pass "stash names unique even with identical clock"

# 8. устаревшие записи реестра удаляются, живые остаются.
fresh
mkdir -p "$TMP/bk/live"
echo x > "$TMP/bk/live/config.fish"
REG="$HOME/.local/state/stylish-dots/backups.tsv"
mkdir -p "$(dirname "$REG")"
printf '2020-01-01\t%s\t%s\n' "$HOME/.config/fish" "$TMP/bk/live" > "$REG"
printf '2020-01-02\t%s\t%s\n' "$HOME/.config/nvim" "$TMP/bk/gone" >> "$REG"
set +e; action_backup_list >"$TMP/out" 2>&1; rc=$?; set -e
[[ $rc -eq 0 ]] || fail "backup list rc=$rc"
[[ $(wc -l < "$REG") -eq 1 ]] || fail "stale registry entry not pruned"
grep -Fq "$TMP/bk/live" "$REG" || fail "live registry entry lost"
! grep -Fq "$TMP/bk/gone" "$TMP/out" || fail "stale entry still listed"
pass "stale registry entries pruned on list"

# 9. before-restore имя тоже уникально при одинаковом времени.
fresh
date() { [[ "$1" == '+%Y%m%d_%H%M%S_%N' ]] && { echo 20260101_000000_000000000; return; }; command date "$@"; }
mkdir -p "$HOME/.config/fish" "$TMP/bk/fish"
echo old > "$TMP/bk/fish/config.fish"
echo one > "$HOME/.config/fish/config.fish"
backup_register "$HOME/.config/fish" "$TMP/bk/fish" >/dev/null
action_restore_backup "$HOME/.config/fish" >/dev/null
echo two > "$HOME/.config/fish/config.fish"
backup_register "$HOME/.config/fish" "$TMP/bk/fish" >/dev/null
action_restore_backup "$HOME/.config/fish" >/dev/null
mapfile -t saved < <(find "$HOME/.config" -maxdepth 1 -name 'fish.before-restore.*' -print | sort)
[[ ${#saved[@]} -eq 2 ]] || fail "expected 2 restore snapshots, got ${#saved[@]}"
[[ "$(cat "${saved[0]}/config.fish")" == one && "$(cat "${saved[1]}/config.fish")" == two ]] || fail "restore snapshot overwritten"
pass "before-restore names unique even with identical clock"

echo "ALL TESTS PASSED"