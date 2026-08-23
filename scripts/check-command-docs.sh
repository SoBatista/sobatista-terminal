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
    # Membership is resolved with an associative array, not
    # `printf ... | grep -Fxq`. In that pipeline `grep -q` exits at its first
    # match and closes the pipe; when it wins the race against the forked
    # printf's flush, printf dies of SIGPIPE and `set -o pipefail` reports the
    # pipeline as failed. A name that *is* documented then gets flagged as
    # missing, which showed up as an intermittent CI failure on early-sorting
    # names such as `burp_off`.
    unset documented_index
    declare -A documented_index=()
    for token in "${documented[@]}"; do
        if [[ -n $token ]]; then
            documented_index["$token"]=1
        fi
    done

    for name in "${names[@]}"; do
        [[ $name == _sb_* ]] && continue
        if [[ -z ${documented_index["$name"]+present} ]]; then
            printf 'Undocumented public shell command in %s: %s\n' \
                "$document" "$name" >&2
            status=1
        fi
    done
done

((status == 0)) || exit 1
printf 'Public command documentation check passed in README and reference (%s names).\n' \
    "${#names[@]}"
