#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
cd "$ROOT"

MODE=${1:---check}
[[ $MODE == --check || $MODE == --publish ]] || {
    printf 'Usage: scripts/release.sh [--check|--publish]\n' >&2
    exit 2
}

scripts/check-version.sh --consistency
IFS= read -r version <VERSION
tag="v$version"
head_sha=$(git rev-parse HEAD)

tag_sha=''
if git rev-parse -q --verify "refs/tags/$tag^{commit}" >/dev/null; then
    tag_sha=$(git rev-parse "refs/tags/$tag^{commit}")
    [[ $tag_sha == "$head_sha" ]] || {
        printf 'ERROR: Existing tag %s points to %s, not %s. Refusing to rewrite it.\n' \
            "$tag" "$tag_sha" "$head_sha" >&2
        exit 1
    }
fi

latest_tag=$(git tag --list 'v[0-9]*.[0-9]*.[0-9]*' --sort=-version:refname \
    | grep -Fxv "$tag" | head -n 1 || true)
if [[ -n $latest_tag ]]; then
    highest=$(printf '%s\n%s\n' "${latest_tag#v}" "$version" | sort -V | tail -n 1)
    [[ $highest == "$version" && ${latest_tag#v} != "$version" ]] || {
        printf 'ERROR: Version %s is not newer than %s.\n' "$version" "$latest_tag" >&2
        exit 1
    }
fi

notes_file=$(mktemp "${TMPDIR:-/tmp}/sobatista-release-notes.XXXXXXXX")
trap 'rm -f -- "$notes_file"' EXIT
awk -v heading="## [$version]" '
    index($0, heading) == 1 {in_section = 1; next}
    in_section && /^## \[/ {exit}
    in_section {print}
' CHANGELOG.md | sed '/./,$!d' >"$notes_file"
[[ -s $notes_file ]] || {
    printf 'ERROR: Release notes for %s are empty.\n' "$version" >&2
    exit 1
}

printf 'Release check passed: %s at %s\n' "$tag" "$head_sha"
[[ $MODE == --publish ]] || exit 0

command -v gh >/dev/null 2>&1 || {
    printf 'ERROR: gh is required to publish a GitHub Release.\n' >&2
    exit 127
}

if [[ -z $tag_sha ]]; then
    git tag -a "$tag" -m "SoBatista Terminal $version"
    git push origin "refs/tags/$tag"
    printf 'Created tag: %s\n' "$tag"
else
    printf 'Tag already exists at this commit: %s\n' "$tag"
fi

if gh release view "$tag" >/dev/null 2>&1; then
    printf 'GitHub Release already exists: %s\n' "$tag"
else
    gh release create "$tag" --title "SoBatista Terminal $version" \
        --notes-file "$notes_file" --verify-tag
    printf 'Created GitHub Release: %s\n' "$tag"
fi
