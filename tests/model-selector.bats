#!/usr/bin/env bats

load helpers/test_helper

setup() {
    make_test_home
    MOCK_LOG="$BATS_TEST_TMPDIR/ollama-args"
    MOCK_INPUT="$BATS_TEST_TMPDIR/ollama-input"
    export MOCK_LOG MOCK_INPUT
    make_mock ollama '
case ${1:-} in
  list)
    printf "NAME ID SIZE MODIFIED\nqwen2.5-coder:7b id1 4GB now\nqwen2.5-coder:14b id2 9GB now\nqwen3-coder:30b id3 18GB now\n"
    ;;
  ps) printf "NAME ID SIZE PROCESSOR UNTIL\nqwen2.5-coder:7b id1 4GB GPU now\n" ;;
  run)
    shift
    printf "%s\n" "$*" >> "$MOCK_LOG"
    cat > "$MOCK_INPUT"
    printf "mock-response\n"
    ;;
  stop) printf "stopped %s\n" "${2:-}" ;;
  --version) printf "ollama version mock\n" ;;
  *) printf "unexpected ollama command: %s\n" "$*" >&2; exit 2 ;;
esac'
}

@test "instant model selection persists in the XDG path" {
    run env -u LOCAL_LLM_MODEL -u LOCAL_LLM_MODEL_STATE \
        HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/xdg" \
        PATH="$BATS_TEST_TMPDIR/bin:$PATH" REPO_ROOT="$REPO_ROOT" \
        bash --noprofile --norc -c '
            source "$REPO_ROOT/config/bash/bash_aliases"
            q14
            printf "runtime=%s\n" "$LOCAL_LLM_MODEL"
            printf "state="; cat "$LOCAL_LLM_MODEL_STATE"
            stat -c "mode=%a" "$LOCAL_LLM_MODEL_STATE"
        '
    [ "$status" -eq 0 ]
    [[ $output == *'runtime=qwen2.5-coder:14b'* ]]
    [[ $output == *'state=qwen2.5-coder:14b'* ]]
    [[ $output == *'mode=600'* ]]
}

@test "fuzzy selection uses installed Ollama model names" {
    make_mock fzf 'cat >/dev/null; printf "qwen3-coder:30b\n"'
    run env -u LOCAL_LLM_MODEL -u LOCAL_LLM_MODEL_STATE \
        HOME="$TEST_HOME" PATH="$BATS_TEST_TMPDIR/bin:$PATH" REPO_ROOT="$REPO_ROOT" \
        bash --noprofile --norc -c '
            source "$REPO_ROOT/config/bash/bash_aliases"
            qm
            printf "%s\n" "$LOCAL_LLM_MODEL"
        '
    [ "$status" -eq 0 ]
    [[ $output == *'qwen3-coder:30b'* ]]
}

@test "missing fzf gives a useful explicit-selection fallback" {
    for command_name in bash awk grep; do
        ln -sf "$(command -v "$command_name")" "$BATS_TEST_TMPDIR/bin/$command_name"
    done
    run env -u LOCAL_LLM_MODEL -u LOCAL_LLM_MODEL_STATE \
        HOME="$TEST_HOME" PATH="$BATS_TEST_TMPDIR/bin" \
        REPO_ROOT="$REPO_ROOT" bash --noprofile --norc -c '
            source "$REPO_ROOT/config/bash/bash_aliases"
            qm
        '
    [ "$status" -eq 2 ]
    [[ $output == *'fzf is unavailable'* ]]
    [[ $output == *'qmodel MODEL'* ]]
}

@test "piped input and instruction are preserved" {
    run env -u LOCAL_LLM_MODEL -u LOCAL_LLM_MODEL_STATE \
        HOME="$TEST_HOME" PATH="$BATS_TEST_TMPDIR/bin:$PATH" REPO_ROOT="$REPO_ROOT" \
        MOCK_LOG="$MOCK_LOG" MOCK_INPUT="$MOCK_INPUT" bash --noprofile --norc -c '
            source "$REPO_ROOT/config/bash/bash_aliases"
            printf "payload with spaces\n" | q "review carefully"
        '
    [ "$status" -eq 0 ]
    run cat "$MOCK_LOG"
    [[ $output == *'qwen2.5-coder:7b'* ]]
    run cat "$MOCK_INPUT"
    [[ $output == *'Instruction:'* ]]
    [[ $output == *'review carefully'* ]]
    [[ $output == *'payload with spaces'* ]]
}

@test "interactive prompt remains one argument under a pseudo-terminal" {
    command -v script >/dev/null 2>&1 || skip 'script(1) is required for the pseudo-terminal test'
    make_mock interactive-q '
source "$REPO_ROOT/config/bash/bash_aliases"
q "interactive words with spaces"'

    run env -u LOCAL_LLM_MODEL -u LOCAL_LLM_MODEL_STATE \
        HOME="$TEST_HOME" PATH="$BATS_TEST_TMPDIR/bin:$PATH" REPO_ROOT="$REPO_ROOT" \
        MOCK_LOG="$MOCK_LOG" MOCK_INPUT="$MOCK_INPUT" \
        script -qec "$BATS_TEST_TMPDIR/bin/interactive-q" /dev/null </dev/null
    [ "$status" -eq 0 ]
    run cat "$MOCK_LOG"
    [[ $output == *'qwen2.5-coder:7b interactive words with spaces'* ]]
}

@test "one-off qrun does not change the persisted model" {
    run env -u LOCAL_LLM_MODEL -u LOCAL_LLM_MODEL_STATE \
        HOME="$TEST_HOME" PATH="$BATS_TEST_TMPDIR/bin:$PATH" REPO_ROOT="$REPO_ROOT" \
        MOCK_LOG="$MOCK_LOG" MOCK_INPUT="$MOCK_INPUT" bash --noprofile --norc -c '
            source "$REPO_ROOT/config/bash/bash_aliases"
            qrun qwen3-coder:30b "one off"
            printf "selected=%s\n" "$LOCAL_LLM_MODEL"
        '
    [ "$status" -eq 0 ]
    [[ $output == *'selected=qwen2.5-coder:7b'* ]]
}
