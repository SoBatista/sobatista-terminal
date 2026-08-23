#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
cd "$ROOT"

mapfile -t files < <(rg --files -0 -g '!scripts/check-secrets.sh' \
    | while IFS= read -r -d '' file; do printf '%s\n' "$file"; done)

((${#files[@]})) || {
    printf 'No repository files found.\n' >&2
    exit 1
}

status=0
check_pattern() {
    local label=$1 pattern=$2
    local matches
    matches=$(rg -i -l -- "$pattern" "${files[@]}" 2>/dev/null || true)
    if [[ -n $matches ]]; then
        printf 'Potential %s in:\n%s\n' "$label" "$matches" >&2
        status=1
    fi
}

check_pattern 'private key' 'BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY'
check_pattern 'OpenAI-style API key' 'sk-[A-Za-z0-9_-]{20,}'
check_pattern 'GitHub token' 'gh[pousr]_[A-Za-z0-9]{20,}'
check_pattern 'AWS access key' 'AKIA[0-9A-Z]{16}'
check_pattern 'Slack token' 'xox[baprs]-[A-Za-z0-9-]{10,}'
check_pattern 'absolute personal home path' '/home/[A-Za-z0-9._-]+/'

for file in "${files[@]}"; do
    case $file in
        */auth.json | auth.json | */session*.db | session*.db | */rollout*.jsonl | rollout*.jsonl)
            printf 'Forbidden Codex state filename: %s\n' "$file" >&2
            status=1
            ;;
    esac
done

# Loopback, wildcard binding, and documentation-only TEST-NET addresses are
# acceptable. Other literal IPv4 addresses require review.
ip_files=$(rg -l '([0-9]{1,3}\.){3}[0-9]{1,3}' "${files[@]}" 2>/dev/null || true)
if [[ -n $ip_files ]]; then
    while IFS= read -r file; do
        [[ -n $file ]] || continue
        if rg -o '([0-9]{1,3}\.){3}[0-9]{1,3}' "$file" \
            | grep -Ev '^(127\.|0\.0\.0\.0$|192\.0\.2\.|198\.51\.100\.|203\.0\.113\.)' \
                >/dev/null; then
            printf 'Potential non-documentation IPv4 literal in: %s\n' "$file" >&2
            status=1
        fi
    done <<<"$ip_files"
fi

if ((status)); then
    printf 'Secret and machine-specific data check failed. Values were intentionally not printed.\n' >&2
    exit 1
fi
printf 'Secret and machine-specific data check passed.\n'
