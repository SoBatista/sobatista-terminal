#!/usr/bin/env bats

load helpers/test_helper

setup() {
    make_test_home
    install_test_shell_files
}

@test "Bash configuration has valid syntax" {
    run bash -n "$REPO_ROOT/config/bash/bashrc" "$REPO_ROOT/config/bash/bash_aliases"
    [ "$status" -eq 0 ]
}

@test "clean interactive shell loads aliases and functions" {
    run env HOME="$TEST_HOME" TERM=xterm-256color \
        bash --noprofile --norc -ic 'source "$HOME/.bashrc"; type termhelp; alias gup' </dev/null
    [ "$status" -eq 0 ]
    [[ $output == *'termhelp is a function'* ]]
    [[ $output == *'git pull --ff-only'* ]]
}

@test "PATH is deduplicated and user local bin is added once" {
    run env HOME="$TEST_HOME" PATH='/usr/bin:/bin:/usr/bin::/bin' TERM=dumb \
        bash --noprofile --norc -ic 'source "$HOME/.bashrc"; printf "%s\n" "$PATH"' </dev/null
    [ "$status" -eq 0 ]
    path_line=${lines[${#lines[@]}-1]}
    [ "$path_line" = "$TEST_HOME/.local/bin:/usr/bin:/bin" ]
}

@test "missing optional integrations do not prevent loading" {
    mkdir -p "$BATS_TEST_TMPDIR/minimal-bin"
    ln -s "$(command -v bash)" "$BATS_TEST_TMPDIR/minimal-bin/bash"
    run env HOME="$TEST_HOME" PATH="$BATS_TEST_TMPDIR/minimal-bin" TERM=dumb \
        "$BATS_TEST_TMPDIR/minimal-bin/bash" --noprofile --norc -ic \
        'source "$HOME/.bashrc"; type mkcd; type qmodels' </dev/null
    [ "$status" -eq 0 ]
    [[ $output == *'mkcd is a function'* ]]
    [[ $output == *'qmodels is a function'* ]]
}
