#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
cd "$ROOT"

PORTABLE=0
case ${1:-} in
    '') ;;
    --portable) PORTABLE=1 ;;
    --help | -h)
        printf 'Usage: scripts/self-test.sh [--portable]\n'
        exit 0
        ;;
    *)
        printf 'Unknown option: %s\n' "$1" >&2
        exit 2
        ;;
esac

printf 'SoBatista Terminal self-test\n'

mapfile -t shell_files < <(
    {
        printf '%s\n' install.sh uninstall.sh
        rg --files scripts -g '*.sh'
        printf '%s\n' config/bash/bashrc config/bash/bash_aliases
    } | sort -u
)
bash -n "${shell_files[@]}"
printf '  PASS Bash syntax\n'

scripts/check-secrets.sh
scripts/check-version.sh --consistency
scripts/check-command-docs.sh

python_toml=0
if command -v python3 >/dev/null 2>&1 && python3 -c 'import tomllib' 2>/dev/null; then
    python3 - <<'PY'
import pathlib
import tomllib

for path in (
    pathlib.Path("config/starship/starship.toml"),
    pathlib.Path("config/codex/local-qwen.config.toml.example"),
):
    with path.open("rb") as handle:
        tomllib.load(handle)
    print(f"  PASS TOML: {path}")
PY
    python_toml=1
fi
if ((!python_toml)); then
    if ((PORTABLE)); then
        printf '  SKIP TOML parser unavailable (portable mode)\n'
    else
        printf '  FAIL Python 3.11+ tomllib is required for full validation.\n' >&2
        exit 1
    fi
fi

grep -Fq '[[AI-Workbench]]' config/terminator/config
grep -Fq 'JetBrainsMono Nerd Font Mono' config/terminator/config
printf '  PASS Terminator configuration\n'

if ((PORTABLE)); then
    printf 'Portable self-test passed. No files were changed.\n'
    exit 0
fi

for dependency in bats shellcheck shfmt; do
    command -v "$dependency" >/dev/null 2>&1 || {
        printf '  FAIL Required test dependency is missing: %s\n' "$dependency" >&2
        exit 127
    }
done

shellcheck "${shell_files[@]}"
printf '  PASS ShellCheck\n'
shfmt -d -i 4 -ci -bn "${shell_files[@]}"
printf '  PASS shfmt\n'
bats tests
printf 'Full self-test passed.\n'
