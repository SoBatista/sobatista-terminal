#!/usr/bin/env bats

load helpers/test_helper

# Each test operates on a throwaway checkout copy so the canonical files can be
# edited and linked without touching the real repository.
setup() {
    make_test_home
    export REPO_ROOT
    CO="$BATS_TEST_TMPDIR/checkout"
    mkdir -p "$CO"
    cp -a "$REPO_ROOT/install.sh" "$REPO_ROOT/uninstall.sh" "$REPO_ROOT/VERSION" \
        "$REPO_ROOT/scripts" "$REPO_ROOT/config" "$CO/"
    export CO
}

inst() { HOME="$TEST_HOME" bash "$CO/install.sh" "$@"; }
uninst() { HOME="$TEST_HOME" bash "$CO/uninstall.sh" "$@"; }
src_aliases() {
    env HOME="$TEST_HOME" TERM=dumb REPO_ROOT="$REPO_ROOT" bash --noprofile --norc -ic \
        "source \"$1\" >/dev/null 2>&1; $2" 2>/dev/null
}

@test "standard installation creates regular copied shell files" {
    inst --configs-only --yes >/dev/null
    [ -f "$TEST_HOME/.bashrc" ] && [ ! -L "$TEST_HOME/.bashrc" ]
    [ -f "$TEST_HOME/.bash_aliases" ] && [ ! -L "$TEST_HOME/.bash_aliases" ]
    cmp -s "$CO/config/bash/bashrc" "$TEST_HOME/.bashrc"
}

@test "--dev-link creates exactly the three shell/Readline links into the checkout" {
    inst --dev-link --configs-only --yes >/dev/null
    for rel in .bashrc .bash_aliases .inputrc; do
        [ -L "$TEST_HOME/$rel" ]
        [[ "$(readlink -- "$TEST_HOME/$rel")" == "$CO/config/"* ]]
    done
    # The non-shell configs remain regular copies.
    [ -f "$TEST_HOME/.config/starship.toml" ] && [ ! -L "$TEST_HOME/.config/starship.toml" ]
    [ -f "$TEST_HOME/.config/terminator/config" ] && [ ! -L "$TEST_HOME/.config/terminator/config" ]
}

@test "the installer scripts hardcode no personal path or username" {
    run grep -nE '/home/[a-z]|sobatistacyber' \
        "$REPO_ROOT/install.sh" "$REPO_ROOT/uninstall.sh" "$REPO_ROOT/scripts/lib/install-common.sh"
    [ "$status" -ne 0 ]
}

@test "--dev-link is idempotent" {
    inst --dev-link --configs-only --yes >/dev/null
    run inst --dev-link --configs-only --yes
    [ "$status" -eq 0 ]
    [ "$(printf '%s\n' "$output" | grep -c 'Unchanged:')" -eq 5 ]
}

@test "--dev-link --dry-run changes nothing" {
    run inst --dev-link --configs-only --dry-run --yes
    [ "$status" -eq 0 ]
    [[ $output == *'[dry-run] link'* ]]
    [ -z "$(find "$TEST_HOME" -mindepth 1 2>/dev/null)" ]
}

@test "a fresh shell over the links loads termhelp, q, and Git shortcuts" {
    inst --dev-link --configs-only --yes >/dev/null
    run src_aliases "$TEST_HOME/.bashrc" \
        '[[ $(type -t termhelp) == function ]] && [[ $(type -t q) == function ]] && alias gup >/dev/null && echo READY'
    [[ $output == *READY* ]]
}

@test "editing the canonical alias file is visible in a new shell without reinstalling" {
    inst --dev-link --configs-only --yes >/dev/null
    printf '\nalias __devlink_probe__=1\n' >>"$CO/config/bash/bash_aliases"
    run src_aliases "$TEST_HOME/.bash_aliases" 'alias __devlink_probe__ >/dev/null && echo VISIBLE'
    [[ $output == *VISIBLE* ]]
}

@test "an already-running shell does not change when the canonical file is edited later" {
    inst --dev-link --configs-only --yes >/dev/null
    run env HOME="$TEST_HOME" TERM=dumb CO="$CO" bash --noprofile --norc -ic '
        source "$HOME/.bash_aliases" >/dev/null 2>&1
        printf "\nalias __late__=1\n" >>"$CO/config/bash/bash_aliases"
        alias __late__ >/dev/null 2>&1 && echo LEAKED || echo STABLE'
    [[ $output == *STABLE* ]]
}

@test "termreload rejects invalid Bash syntax without replacing the shell" {
    printf 'this is ( invalid\n' >"$TEST_HOME/.bashrc"
    : >"$TEST_HOME/.bash_aliases"
    run env HOME="$TEST_HOME" TERM=dumb REPO_ROOT="$REPO_ROOT" bash --noprofile --norc -ic \
        'source "$REPO_ROOT/config/bash/bash_aliases" >/dev/null 2>&1; termreload; echo "AFTER=$?"'
    [[ $output == *'Syntax error in'* ]]
    [[ $output == *'AFTER=1'* ]]
}

@test "termdev_status detects regular, symlink, broken, and missing states" {
    printf 'x\n' >"$TEST_HOME/.bashrc"                                # regular
    ln -s "$CO/config/bash/bash_aliases" "$TEST_HOME/.bash_aliases"   # valid symlink
    ln -s "$TEST_HOME/no-such-target" "$TEST_HOME/.inputrc"           # broken symlink
    run src_aliases "$REPO_ROOT/config/bash/bash_aliases" 'termdev_status'
    [[ $output == *'.bashrc'*'regular file'* ]]
    [[ $output == *'.bash_aliases'*'symlink -> '"$CO"/* ]]
    [[ $output == *'.inputrc'*'broken symlink'* ]]
    # missing state
    rm -f "$TEST_HOME/.bashrc"
    run src_aliases "$REPO_ROOT/config/bash/bash_aliases" 'termdev_status'
    [[ $output == *'.bashrc'*'missing'* ]]
}

@test "uninstall removes project links but never deletes their repository targets" {
    inst --dev-link --configs-only --yes >/dev/null
    uninst --yes >/dev/null
    [ ! -e "$TEST_HOME/.bashrc" ] && [ ! -L "$TEST_HOME/.bashrc" ]
    # the canonical target the link pointed at is untouched
    [ -f "$CO/config/bash/bashrc" ]
}

@test "uninstall preserves a user-retargeted managed link" {
    inst --dev-link --configs-only --yes >/dev/null
    ln -sfn /tmp/somewhere-else "$TEST_HOME/.bashrc"
    run uninst --yes
    [[ $output == *'Preserved retargeted or replaced link'* ]]
    [ -L "$TEST_HOME/.bashrc" ]
}

@test "copy-to-link and link-to-copy transitions both work" {
    inst --configs-only --yes >/dev/null
    [ ! -L "$TEST_HOME/.bashrc" ]
    inst --dev-link --configs-only --yes >/dev/null
    [ -L "$TEST_HOME/.bashrc" ]
    inst --configs-only --yes >/dev/null
    [ -f "$TEST_HOME/.bashrc" ] && [ ! -L "$TEST_HOME/.bashrc" ]
}

@test "restore recreates an original user symlink" {
    ln -s /dev/null "$TEST_HOME/.bashrc"
    inst --configs-only --yes >/dev/null
    [ ! -L "$TEST_HOME/.bashrc" ]
    local backup
    backup=$(HOME="$TEST_HOME" bash "$CO/uninstall.sh" --list-backups | awk 'NR==2{print $1}')
    uninst --restore "$backup" --yes >/dev/null
    [ -L "$TEST_HOME/.bashrc" ] && [ "$(readlink -- "$TEST_HOME/.bashrc")" = /dev/null ]
}

@test "--dev-link with a checkout path containing spaces links correctly" {
    local spaced="$BATS_TEST_TMPDIR/check out dir"
    cp -a "$CO" "$spaced"
    HOME="$TEST_HOME" bash "$spaced/install.sh" --dev-link --configs-only --yes >/dev/null
    [ -L "$TEST_HOME/.bashrc" ]
    [ "$(readlink -- "$TEST_HOME/.bashrc")" = "$spaced/config/bash/bashrc" ]
}

@test "--dev-link is rejected together with --self-test" {
    run inst --dev-link --self-test
    [ "$status" -eq 2 ]
    [[ $output == *'cannot be combined with --self-test'* ]]
}
