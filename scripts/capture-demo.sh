#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
mode=${1:-hero}

case $mode in
    hero)
        printf '\033[38;2;0;230;138mSoBatista Terminal\033[0m  '
        printf '\033[38;2;94;235;255mBlack Ice\033[0m\n'
        printf 'Version       %s\n' "$(<"$ROOT/VERSION")"
        printf 'Shell         Bash\nTerminal      Terminator / AI-Workbench\n'
        printf 'Local AI      qwen2.5-coder:7b (default)\n'
        printf 'Help          termhelp\n'
        printf '\nThis output is deterministic and contains no machine identity or network data.\n'
        ;;
    diagnostics)
        printf 'Safe screenshot checklist\n'
        printf '  [ ] no tokens, credentials, private paths, IPs, or client names\n'
        printf '  [ ] repository status contains only intended public files\n'
        printf '  [ ] terminal title and neighboring windows contain no personal data\n'
        ;;
    *)
        printf 'Usage: scripts/capture-demo.sh {hero|diagnostics}\n' >&2
        exit 2
        ;;
esac
