#!/usr/bin/env bats

load helpers/test_helper

setup() {
    make_test_home
    export REPO_ROOT
}

@test "the prompt has no clock and time is disabled" {
    run grep -F '$time' "$REPO_ROOT/config/starship/starship.toml"
    [ "$status" -ne 0 ]
    run python3 - "$REPO_ROOT/config/starship/starship.toml" <<'PY'
import sys, tomllib
data = tomllib.load(open(sys.argv[1], "rb"))
raise SystemExit(0 if data.get("time", {}).get("disabled") is True else 1)
PY
    [ "$status" -eq 0 ]
}

@test "starship TOML is valid and keeps the Black Ice background" {
    run python3 - "$REPO_ROOT/config/starship/starship.toml" <<'PY'
import sys, tomllib
data = tomllib.load(open(sys.argv[1], "rb"))
raise SystemExit(0 if data["palettes"]["black_ice"]["background"] == "#070B0D" else 1)
PY
    [ "$status" -eq 0 ]
}

@test "the prompt format is a single connected bar with one transition" {
    run python3 - "$REPO_ROOT/config/starship/starship.toml" <<'PY'
import sys, tomllib
fmt = tomllib.load(open(sys.argv[1], "rb"))["format"]
transition, open_cap, close_cap = chr(0xE0B0), chr(0xE0B6), chr(0xE0B4)
ok = (
    fmt.count(transition) == 1
    and fmt.count(open_cap) == 1
    and fmt.count(close_cap) == 1
    and "\n" not in fmt
)
raise SystemExit(0 if ok else 1)
PY
    [ "$status" -eq 0 ]
}

# The prompt identity is captured to a file because an interactive shell prints
# harmless "no job control" lines to stderr that would otherwise mix into output.
@test "screenshot mode substitutes a safe identity" {
    env HOME="$TEST_HOME" USER=realuser HOSTNAME=secret.internal \
        SOBATISTA_SCREENSHOT_MODE=1 TERM=dumb REPO_ROOT="$REPO_ROOT" OUT="$TEST_HOME/id" \
        bash --noprofile --norc -ic \
        'source "$REPO_ROOT/config/bash/bashrc" >/dev/null 2>&1; printf "%s" "$SOBATISTA_PROMPT_IDENTITY" >"$OUT"' \
        2>/dev/null
    run cat "$TEST_HOME/id"
    [ "$status" -eq 0 ]
    [[ $output == "sobatista@blackice" ]]
    [[ $output != *realuser* ]]
    [[ $output != *secret* ]]
}

@test "normal shells keep the real identity, short host only" {
    env HOME="$TEST_HOME" USER=realuser HOSTNAME=box.example.com TERM=dumb \
        REPO_ROOT="$REPO_ROOT" OUT="$TEST_HOME/id" \
        bash --noprofile --norc -ic \
        'unset SOBATISTA_SCREENSHOT_MODE; source "$REPO_ROOT/config/bash/bashrc" >/dev/null 2>&1; printf "%s" "$SOBATISTA_PROMPT_IDENTITY" >"$OUT"' \
        2>/dev/null
    run cat "$TEST_HOME/id"
    [ "$status" -eq 0 ]
    [[ $output == "realuser@box" ]]
}

@test "termhelp git documents the prompt indicators" {
    run env HOME="$TEST_HOME" TERM=dumb REPO_ROOT="$REPO_ROOT" \
        bash --noprofile --norc -ic \
        'source "$REPO_ROOT/config/bash/bash_aliases" >/dev/null 2>&1; termhelp git'
    [ "$status" -eq 0 ]
    [[ $output == *"commits to push"* ]]
    [[ $output == *"⇡"* ]]
    [[ $output == *"untracked"* ]]
}

@test "terminator ships a scoped Black Ice separator stylesheet" {
    [ -f "$REPO_ROOT/config/terminator/gtk.css" ]
    run grep -F '#18222C' "$REPO_ROOT/config/terminator/gtk.css"
    [ "$status" -eq 0 ]
    run grep -F 'terminator-terminal-window' "$REPO_ROOT/config/terminator/gtk.css"
    [ "$status" -eq 0 ]
}
