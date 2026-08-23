#!/usr/bin/env bats

load helpers/test_helper

setup() {
    export REPO_ROOT
    TCFG="$REPO_ROOT/config/terminator/config"
    export TCFG
}

# Minimal, dependency-free reader for a Terminator profile block.
profile_value() {
    python3 - "$TCFG" "$1" "$2" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
name, key = sys.argv[2], sys.argv[3]
m = re.search(r'^\s*\[\[' + re.escape(name) + r'\]\]\s*$', text, re.M)
if not m:
    raise SystemExit(1)
rest = text[m.end():]
stop = re.search(r'^\s*(\[\[|\[)', rest, re.M)
block = rest[:stop.start()] if stop else rest
for line in block.splitlines():
    mm = re.match(r'\s*([A-Za-z_]+)\s*=\s*(.*)', line)
    if mm and mm.group(1) == key:
        print(mm.group(2).strip().strip('"'))
        raise SystemExit(0)
raise SystemExit(2)
PY
}

@test "the default profile is subtly transparent at darkness 0.94 on #070B0D" {
    [ "$(profile_value default background_type)" = "transparent" ]
    [ "$(profile_value default background_darkness)" = "0.94" ]
    [ "$(profile_value default background_color)" = "#070B0D" ]
}

@test "a solid BlackIce-Solid profile exists and uses #070B0D" {
    [ "$(profile_value BlackIce-Solid background_type)" = "solid" ]
    [ "$(profile_value BlackIce-Solid background_color)" = "#070B0D" ]
}

@test "both profiles keep the exact Nerd Font family" {
    [ "$(profile_value default font)" = "JetBrainsMono Nerd Font Mono 11" ]
    [ "$(profile_value BlackIce-Solid font)" = "JetBrainsMono Nerd Font Mono 11" ]
}

@test "AI-Workbench keeps the layout and muted slate separators" {
    run grep -F '[[AI-Workbench]]' "$TCFG"
    [ "$status" -eq 0 ]
    # thin handle plus the scoped slate stylesheet
    run grep -E '^\s*handle_size = 1$' "$TCFG"
    [ "$status" -eq 0 ]
    [ -f "$REPO_ROOT/config/terminator/gtk.css" ]
    run grep -F '#18222C' "$REPO_ROOT/config/terminator/gtk.css"
    [ "$status" -eq 0 ]
}

@test "the terminator config carries no personal path or identity" {
    run grep -nEi '/home/[a-z]|sobatistacyber|@sobatista\b' "$TCFG"
    [ "$status" -ne 0 ]
}

@test "the terminator config parses under Terminator's own config parser" {
    python3 -c 'import configobj' 2>/dev/null || skip "configobj (Terminator's parser) not installed"
    run python3 - "$TCFG" <<'PY'
import sys
from configobj import ConfigObj
c = ConfigObj(sys.argv[1], raise_errors=True)
p = c["profiles"]
ok = (
    p["default"]["background_type"] == "transparent"
    and p["default"]["background_darkness"] == "0.94"
    and p["BlackIce-Solid"]["background_type"] == "solid"
    and "AI-Workbench" in c["layouts"]
)
raise SystemExit(0 if ok else 1)
PY
    [ "$status" -eq 0 ]
}
