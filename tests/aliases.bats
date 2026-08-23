#!/usr/bin/env bats

load helpers/test_helper

setup() {
    make_test_home
}

@test "required public commands resolve" {
    run env HOME="$TEST_HOME" REPO_ROOT="$REPO_ROOT" bash --noprofile --norc -O expand_aliases -c '
        source "$REPO_ROOT/config/bash/bash_aliases"
        for name in mkcd croot backup termhelp cmdhelp q qm q7 q14 q30 qrun qfile \
            qdiff qstaged qcommit qlog qcmd qps qstop qstopall llm_check \
            cx cxask cxl cxlask cxd cxr cxer cxlr system_update apps_update \
            updateall updatecodex updateollama updatestarship qmodels_update \
            restartcheck nmap_services nmap_all_tcp certinfo burp_on burp_off burp_status; do
            type "$name" >/dev/null || exit 1
        done
    '
    [ "$status" -eq 0 ]
}

@test "dangerous Git behavior is not disguised" {
    run env HOME="$TEST_HOME" REPO_ROOT="$REPO_ROOT" bash --noprofile --norc -O expand_aliases -c '
        source "$REPO_ROOT/config/bash/bash_aliases"
        alias gup
        alias gpf
    '
    [ "$status" -eq 0 ]
    [[ $output == *'pull --ff-only'* ]]
    [[ $output == *'push --force-with-lease'* ]]
    [[ $output != *'reset --hard'* ]]
}

@test "help exposes every required topic without fzf" {
    local topic
    for topic in keys ai git shell updates security discovery; do
        run env HOME="$TEST_HOME" REPO_ROOT="$REPO_ROOT" bash --noprofile --norc -c \
            'source "$REPO_ROOT/config/bash/bash_aliases"; termhelp "$1"' bash "$topic"
        [ "$status" -eq 0 ]
        [ -n "$output" ]
    done
}

@test "authorized security help carries an authorization warning" {
    run env HOME="$TEST_HOME" REPO_ROOT="$REPO_ROOT" bash --noprofile --norc -c \
        'source "$REPO_ROOT/config/bash/bash_aliases"; termhelp security'
    [ "$status" -eq 0 ]
    [[ $output == *'AUTHORIZED TARGETS ONLY'* ]]
}
