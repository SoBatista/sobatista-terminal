#!/usr/bin/env bats

load helpers/test_helper

setup() {
    make_test_home
    UPDATE_LOG="$BATS_TEST_TMPDIR/update-log"
    export UPDATE_LOG
    make_mock sudo 'printf "sudo %s\n" "$*" >> "$UPDATE_LOG"; "$@"'
    make_mock apt-get 'printf "apt-get %s\n" "$*" >> "$UPDATE_LOG"'
}

@test "system_update uses the detected apt command sequence" {
    run env HOME="$TEST_HOME" PATH="$BATS_TEST_TMPDIR/bin:/usr/bin:/bin" \
        REPO_ROOT="$REPO_ROOT" UPDATE_LOG="$UPDATE_LOG" bash --noprofile --norc -c '
            source "$REPO_ROOT/config/bash/bash_aliases"
            system_update
        '
    [ "$status" -eq 0 ]
    run cat "$UPDATE_LOG"
    [[ $output == *'apt-get update'* ]]
    [[ $output == *'apt-get upgrade'* ]]
}

@test "update help states explicit boundaries and rejects cache dropping" {
    run env HOME="$TEST_HOME" REPO_ROOT="$REPO_ROOT" bash --noprofile --norc -c '
        source "$REPO_ROOT/config/bash/bash_aliases"
        termhelp updates
    '
    [ "$status" -eq 0 ]
    [[ $output == *'AppImages'* ]]
    [[ $output == *'automatically reclaimed'* ]]
    ! rg -n 'drop_caches|/proc/sys/vm/drop_caches' "$REPO_ROOT/config" "$REPO_ROOT/scripts"
}

@test "version, TOML, Terminator, and secret checks pass" {
    run "$REPO_ROOT/scripts/check-version.sh" --consistency
    [ "$status" -eq 0 ]
    run "$REPO_ROOT/scripts/check-secrets.sh"
    [ "$status" -eq 0 ]
    run python3 -c '
import tomllib
for path in ("config/starship/starship.toml", "config/codex/local-qwen.config.toml.example"):
    with open(path, "rb") as handle:
        tomllib.load(handle)
' 
    [ "$status" -eq 0 ]
    run grep -F '[[AI-Workbench]]' "$REPO_ROOT/config/terminator/config"
    [ "$status" -eq 0 ]
}
