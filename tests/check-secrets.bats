#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load helpers/test_helper

setup() { export REPO_ROOT; }

@test "check-secrets fails clearly and nonzero when ripgrep is missing" {
    # A PATH holding only the essentials the preflight needs, but no ripgrep.
    tmpbin=$(mktemp -d "$BATS_TEST_TMPDIR/nobin.XXXXXX")
    for c in bash env dirname; do ln -s "$(command -v "$c")" "$tmpbin/$c"; done
    run -127 env PATH="$tmpbin" bash "$REPO_ROOT/scripts/check-secrets.sh"
    [[ $output == *"ripgrep (rg) is required"* ]]
    [[ $output != *"No repository files found"* ]]
}

@test "check-secrets passes on the clean repository when ripgrep is present" {
    command -v rg >/dev/null 2>&1 || skip "ripgrep not installed"
    run bash "$REPO_ROOT/scripts/check-secrets.sh"
    [ "$status" -eq 0 ]
    [[ $output == *"passed"* ]]
}
