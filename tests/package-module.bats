#!/usr/bin/env bats

load helpers/test_helper

setup() {
    make_test_home
    export REPO_ROOT
    CFG="$REPO_ROOT/config/starship/starship.toml"
    export CFG
}

@test "package module is present, ordered after Git, before docker/conda" {
    run python3 - "$CFG" <<'PY'
import sys, tomllib
d = tomllib.load(open(sys.argv[1], "rb"))
fmt = d["format"]
i_status, i_pkg, i_docker = fmt.find("$git_status"), fmt.find("$package"), fmt.find("$docker_context")
ok = "$package" in fmt and 0 <= i_status < i_pkg < i_docker
raise SystemExit(0 if ok else 1)
PY
    [ "$status" -eq 0 ]
}

@test "the package segment is a bare version: no pkg label, no icon, v-prefixed" {
    run python3 - "$CFG" <<'PY'
import sys, tomllib
pkg = tomllib.load(open(sys.argv[1], "rb"))["package"]
fmt = pkg["format"]
ok = (
    fmt == "[ $version ]($style)"
    and pkg.get("version_format") == "v${raw}"
    and "pkg" not in fmt
    and "$symbol" not in fmt
    and all(ord(c) < 128 for c in fmt)  # no Nerd Font / emoji icon
)
raise SystemExit(0 if ok else 1)
PY
    [ "$status" -eq 0 ]
}

@test "no language or runtime version module is in the top-level format" {
    run python3 - "$CFG" <<'PY'
import re, sys, tomllib
fmt = tomllib.load(open(sys.argv[1], "rb"))["format"]
mods = set(re.findall(r"\$([a-z_][a-z_0-9]*)", fmt))  # whole module tokens
runtimes = {"python", "nodejs", "rust", "golang", "c", "bun", "php",
            "java", "kotlin", "haskell", "ruby", "deno"}
raise SystemExit(0 if not (mods & runtimes) else 1)
PY
    [ "$status" -eq 0 ]
}

@test "language/runtime module sections are removed from the config" {
    run python3 - "$CFG" <<'PY'
import sys, tomllib
d = tomllib.load(open(sys.argv[1], "rb"))
gone = ("c", "rust", "golang", "nodejs", "bun", "php", "java", "kotlin", "haskell", "python")
raise SystemExit(0 if not any(k in d for k in gone) else 1)
PY
    [ "$status" -eq 0 ]
}

@test "the prompt hardcodes no project name, version, or personal path" {
    run grep -nEi 'sobatista-ai|sobai|0\.1\.0|/home/[a-z]' "$CFG"
    [ "$status" -ne 0 ]
}

@test "the Black Ice palette is exactly the approved set, with no pink or magenta" {
    run python3 - "$CFG" <<'PY'
import sys, tomllib
p = tomllib.load(open(sys.argv[1], "rb"))["palettes"]["black_ice"]
approved = {
    "background": "#070B0D", "surface": "#111820", "secondary": "#18222C",
    "green": "#00E68A", "cyan": "#5EEBFF", "teal": "#22C7A9", "text": "#D6E7E9",
    "muted": "#64748B", "warning": "#F5C451", "error": "#FF4D5A",
}
def magenta(h):
    r, g, b = int(h[1:3], 16), int(h[3:5], 16), int(h[5:7], 16)
    return r > 150 and b > 120 and g < 120
raise SystemExit(0 if p == approved and not any(magenta(v) for v in p.values()) else 1)
PY
    [ "$status" -eq 0 ]
}

@test "the time module remains disabled" {
    run python3 - "$CFG" <<'PY'
import sys, tomllib
d = tomllib.load(open(sys.argv[1], "rb"))
raise SystemExit(0 if d.get("time", {}).get("disabled") is True and "$time" not in d["format"] else 1)
PY
    [ "$status" -eq 0 ]
}

@test "a PEP 621 pyproject renders a bare v<version> with no pkg text" {
    command -v starship >/dev/null 2>&1 || skip "starship not installed"
    proj=$(mktemp -d "$BATS_TEST_TMPDIR/proj.XXXXXX")
    printf '[project]\nname = "demo"\nversion = "9.9.9"\n' >"$proj/pyproject.toml"
    run env STARSHIP_CONFIG="$CFG" bash -c "cd '$proj' && starship module package 2>/dev/null | sed -E 's/\x1b\[[0-9;]*m//g'"
    [ "$status" -eq 0 ]
    [[ $output == *"v9.9.9"* ]]
    [[ $output != *pkg* ]]
}

@test "no Python version or icon appears in a Python project prompt" {
    command -v starship >/dev/null 2>&1 || skip "starship not installed"
    app="$BATS_TEST_TMPDIR/app"
    mkdir -p "$app"
    printf '[project]\nname = "demo"\nversion = "9.9.9"\n' >"$app/pyproject.toml"
    (cd "$app" && git init -q)
    env STARSHIP_CONFIG="$CFG" SOBATISTA_PROMPT_IDENTITY="x@y" \
        bash -c "cd '$app' && starship prompt 2>/dev/null" >"$BATS_TEST_TMPDIR/py.out"
    run python3 - "$BATS_TEST_TMPDIR/py.out" <<'PY'
import sys, re
data = open(sys.argv[1], encoding="utf-8", errors="replace").read()
data = re.sub(r"\x1b\[[0-9;]*m", "", data).replace("\\[", "").replace("\\]", "")
ok = "v9.9.9" in data and not re.search(r"py[0-9]", data) and "\U0001F40D" not in data and "v3." not in data
raise SystemExit(0 if ok else 1)
PY
    [ "$status" -eq 0 ]
}

@test "no version segment appears outside a versioned project" {
    command -v starship >/dev/null 2>&1 || skip "starship not installed"
    plain=$(mktemp -d "$BATS_TEST_TMPDIR/plain.XXXXXX")
    run env STARSHIP_CONFIG="$CFG" bash -c "cd '$plain' && starship module package 2>/dev/null | sed -E 's/\x1b\[[0-9;]*m//g'"
    [ -z "${output// /}" ]
}

@test "the bar keeps exactly one of each separator when modules are absent" {
    command -v starship >/dev/null 2>&1 || skip "starship not installed"
    plain=$(mktemp -d "$BATS_TEST_TMPDIR/sep.XXXXXX")
    env STARSHIP_CONFIG="$CFG" SOBATISTA_PROMPT_IDENTITY="x@y" \
        bash -c "cd '$plain' && starship prompt 2>/dev/null" >"$BATS_TEST_TMPDIR/prompt.out"
    run python3 - "$BATS_TEST_TMPDIR/prompt.out" <<'PY'
import sys, re
data = open(sys.argv[1], encoding="utf-8", errors="replace").read()
data = re.sub(r"\x1b\[[0-9;]*m", "", data).replace("\\[", "").replace("\\]", "")
tr, op, cl = chr(0xE0B0), chr(0xE0B6), chr(0xE0B4)
raise SystemExit(0 if data.count(tr) == 1 and data.count(op) == 1 and data.count(cl) == 1 else 1)
PY
    [ "$status" -eq 0 ]
}
