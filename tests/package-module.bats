#!/usr/bin/env bats

load helpers/test_helper

setup() {
    make_test_home
    export REPO_ROOT
    CFG="$REPO_ROOT/config/starship/starship.toml"
    export CFG
}

@test "package module is present and ordered after Git, before the runtime" {
    run python3 - "$CFG" <<'PY'
import sys, tomllib
d = tomllib.load(open(sys.argv[1], "rb"))
fmt = d["format"]
i_status, i_pkg, i_py = fmt.find("$git_status"), fmt.find("$package"), fmt.find("$python")
ok = (
    "$package" in fmt
    and 0 <= i_status < i_pkg < i_py
    and d["package"]["format"].strip().startswith("[ pkg $version")
    and d["package"]["style"] == "bg:secondary fg:text"
)
raise SystemExit(0 if ok else 1)
PY
    [ "$status" -eq 0 ]
}

@test "python runtime is explicitly labeled py, not an ambiguous icon" {
    run python3 - "$CFG" <<'PY'
import sys, tomllib
py = tomllib.load(open(sys.argv[1], "rb"))["python"]
ok = "py$version" in py["format"] and "$symbol" not in py["format"] and py.get("version_format") == "${raw}"
raise SystemExit(0 if ok else 1)
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
ok = p == approved and not any(magenta(v) for v in p.values())
raise SystemExit(0 if ok else 1)
PY
    [ "$status" -eq 0 ]
}

@test "the time module remains disabled after adding package" {
    run python3 - "$CFG" <<'PY'
import sys, tomllib
d = tomllib.load(open(sys.argv[1], "rb"))
raise SystemExit(0 if d.get("time", {}).get("disabled") is True and "$time" not in d["format"] else 1)
PY
    [ "$status" -eq 0 ]
}

@test "a PEP 621 pyproject renders pkg with its declared version" {
    command -v starship >/dev/null 2>&1 || skip "starship not installed"
    proj=$(mktemp -d "$BATS_TEST_TMPDIR/proj.XXXXXX")
    printf '[project]\nname = "demo-pkg"\nversion = "9.9.9"\n' >"$proj/pyproject.toml"
    run env STARSHIP_CONFIG="$CFG" bash -c "cd '$proj' && starship module package 2>/dev/null | sed -E 's/\x1b\[[0-9;]*m//g'"
    [ "$status" -eq 0 ]
    [[ $output == *"pkg v9.9.9"* ]]
}

@test "python renders the py label with the interpreter version" {
    command -v starship >/dev/null 2>&1 || skip "starship not installed"
    command -v python3 >/dev/null 2>&1 || skip "python3 not installed"
    proj=$(mktemp -d "$BATS_TEST_TMPDIR/pyproj.XXXXXX")
    printf '[project]\nname = "demo"\nversion = "1.0.0"\n' >"$proj/pyproject.toml"
    run env STARSHIP_CONFIG="$CFG" bash -c "cd '$proj' && starship module python 2>/dev/null | sed -E 's/\x1b\[[0-9;]*m//g'"
    [ "$status" -eq 0 ]
    [[ ${output// /} == py[0-9]* ]]
}

@test "package and python vanish outside a project" {
    command -v starship >/dev/null 2>&1 || skip "starship not installed"
    plain=$(mktemp -d "$BATS_TEST_TMPDIR/plain.XXXXXX")
    run env STARSHIP_CONFIG="$CFG" bash -c "cd '$plain' && starship module package 2>/dev/null | sed -E 's/\x1b\[[0-9;]*m//g'"
    [ -z "${output// /}" ]
    run env STARSHIP_CONFIG="$CFG" bash -c "cd '$plain' && starship module python 2>/dev/null | sed -E 's/\x1b\[[0-9;]*m//g'"
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
