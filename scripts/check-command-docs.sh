#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
cd "$ROOT"

mapfile -t names < <(
    sed -n -E \
        -e 's/^[[:space:]]*alias([[:space:]]+--)?[[:space:]]+([^=]+)=.*/\2/p' \
        -e 's/^[[:space:]]*([A-Za-z][A-Za-z0-9_]*)\(\)[[:space:]]*\{.*/\1/p' \
        config/bash/bashrc config/bash/bash_aliases \
        | sort -u
)

status=0
for document in README.md docs/commands.md; do
    # The extraction pattern intentionally contains literal Markdown backticks.
    # shellcheck disable=SC2016
    mapfile -t documented < <(
        rg -o '`[^`]+`' "$document" \
            | sed -E 's/^`|`$//g' \
            | awk '{print $1}' \
            | sort -u
    )
    for name in "${names[@]}"; do
        [[ $name == _sb_* ]] && continue
        if ! printf '%s\n' "${documented[@]}" | grep -Fxq -- "$name"; then
            printf 'Undocumented public shell command in %s: %s\n' \
                "$document" "$name" >&2
            status=1
        fi
    done
done

((status == 0)) || exit 1
printf 'Public command documentation check passed in README and reference (%s names).\n' \
    "${#names[@]}"
