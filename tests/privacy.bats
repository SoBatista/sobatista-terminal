#!/usr/bin/env bats

load helpers/test_helper

setup() {
    make_test_home
    export REPO_ROOT
    BIN="$BATS_TEST_TMPDIR/bin"
    mkdir -p "$BIN"
    export BIN
}

mock_terminator() {
    cat >"$BIN/terminator" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$@" >"$BATS_TEST_TMPDIR/targs"
EOF
    chmod +x "$BIN/terminator"
}

@test "privacy opens a BlackIce-Solid window in the current directory, spaces preserved" {
    mock_terminator
    wd="$TEST_HOME/dir with spaces"
    mkdir -p "$wd"
    env HOME="$TEST_HOME" TERM=dumb PATH="$BIN:$PATH" REPO_ROOT="$REPO_ROOT" WD="$wd" \
        bash --noprofile --norc -ic '
            source "$REPO_ROOT/config/bash/bash_aliases" >/dev/null 2>&1
            cd "$WD"
            privacy
        ' 2>/dev/null
    # The window is launched in the background and disowned; poll for its args.
    for _ in 1 2 3 4 5 6 7 8 9 10; do [ -f "$BATS_TEST_TMPDIR/targs" ] && break; sleep 0.1; done
    run cat "$BATS_TEST_TMPDIR/targs"
    [ "$status" -eq 0 ]
    [[ $output == *'--no-dbus'* ]]
    [[ $output == *'--profile=BlackIce-Solid'* ]]
    [[ $output == *"--working-directory=$wd"* ]]
}

@test "privacy does not use eval" {
    run env HOME="$TEST_HOME" REPO_ROOT="$REPO_ROOT" bash --noprofile --norc -c '
        source "$REPO_ROOT/config/bash/bash_aliases" >/dev/null 2>&1
        declare -f privacy'
    [ "$status" -eq 0 ]
    [[ $output != *eval* ]]
}

@test "privacy fails clearly and nonzero when Terminator is unavailable" {
    nob="$BATS_TEST_TMPDIR/nob"
    mkdir -p "$nob"
    for c in bash env; do ln -s "$(command -v "$c")" "$nob/$c"; done
    env HOME="$TEST_HOME" TERM=dumb PATH="$nob" REPO_ROOT="$REPO_ROOT" OUT="$BATS_TEST_TMPDIR/rc" \
        "$nob/bash" --noprofile --norc -ic '
            source "$REPO_ROOT/config/bash/bash_aliases" >/dev/null 2>&1
            privacy
            printf "rc=%s\n" "$?" >"$OUT"
        ' 2>/dev/null
    run cat "$BATS_TEST_TMPDIR/rc"
    [[ $output == "rc=127" ]]
}

@test "termhelp privacy documents the solid profile and screen-sharing use" {
    run env HOME="$TEST_HOME" TERM=dumb REPO_ROOT="$REPO_ROOT" bash --noprofile --norc -ic '
        source "$REPO_ROOT/config/bash/bash_aliases" >/dev/null 2>&1
        termhelp privacy'
    [ "$status" -eq 0 ]
    [[ $output == *'BlackIce-Solid'* ]]
    [[ $output == *'screen sharing'* ]]
    [[ $output == *'90%'* ]]
}
