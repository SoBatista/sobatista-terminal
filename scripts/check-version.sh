#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
cd "$ROOT"

usage() {
    cat <<'EOF'
Usage: scripts/check-version.sh [--consistency | --pr BASE_REF]

--consistency validates VERSION and its documented release section.
--pr also requires exactly one release:* label in RELEASE_LABELS and verifies
that VERSION is the matching single SemVer increment from BASE_REF.
EOF
}

semver_valid() {
    [[ $1 =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]
}

split_version() {
    IFS=. read -r VERSION_MAJOR VERSION_MINOR VERSION_PATCH <<<"$1"
}

check_consistency() {
    [[ -f VERSION ]] || {
        printf 'VERSION is missing.\n' >&2
        return 1
    }
    local version
    IFS= read -r version <VERSION || true
    semver_valid "$version" || {
        printf 'Invalid SemVer in VERSION: %s\n' "$version" >&2
        return 1
    }
    [[ $(grep -c '' VERSION) -le 1 ]] || {
        printf 'VERSION must contain exactly one line.\n' >&2
        return 1
    }
    grep -Fqx "## [$version] - $(date +%F)" CHANGELOG.md \
        || grep -Eq "^## \[$version\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$" CHANGELOG.md || {
        printf 'CHANGELOG.md has no dated section for %s.\n' "$version" >&2
        return 1
    }
    grep -Fq "Version: \`$version\`" README.md || {
        printf 'README.md does not declare the expected version line for %s.\n' "$version" >&2
        return 1
    }
    printf 'Version consistency passed: %s\n' "$version"
}

check_pr() {
    local base_ref=$1 current base labels label_count=0 bump=''
    IFS= read -r current <VERSION || true
    if ! git rev-parse --verify --quiet "$base_ref^{commit}" >/dev/null 2>&1; then
        printf 'Base ref not found: %s. Fetch it before validating (e.g. git fetch origin).\n' \
            "$base_ref" >&2
        return 1
    fi
    if base=$(git show "$base_ref:VERSION" 2>/dev/null); then
        base=${base%%$'\n'*}
    else
        # The base ref exists but predates the VERSION file (first versioned PR).
        base='0.0.0'
    fi
    semver_valid "$base" || {
        printf 'Base VERSION is not valid SemVer: %s\n' "$base" >&2
        return 1
    }

    labels=",${RELEASE_LABELS:-},"
    local candidate
    for candidate in major minor patch; do
        if [[ $labels == *",release:$candidate,"* ]]; then
            ((label_count += 1))
            bump=$candidate
        fi
    done
    ((label_count == 1)) || {
        printf 'A PR needs exactly one label: release:major, release:minor, or release:patch.\n' >&2
        return 1
    }

    split_version "$base"
    local base_major=$VERSION_MAJOR base_minor=$VERSION_MINOR base_patch=$VERSION_PATCH
    split_version "$current"
    local expected
    case $bump in
        major) expected="$((base_major + 1)).0.0" ;;
        minor) expected="$base_major.$((base_minor + 1)).0" ;;
        patch) expected="$base_major.$base_minor.$((base_patch + 1))" ;;
    esac
    [[ $current == "$expected" ]] || {
        printf 'release:%s requires VERSION %s; found %s (base %s).\n' \
            "$bump" "$expected" "$current" "$base" >&2
        return 1
    }
    printf 'PR release metadata passed: %s -> %s (%s)\n' "$base" "$current" "$bump"
}

if (($# == 0)); then
    set -- --consistency
fi

case $1 in
    --consistency)
        [[ $# -eq 1 ]] || {
            usage >&2
            exit 2
        }
        check_consistency
        ;;
    --pr)
        [[ $# -eq 2 ]] || {
            usage >&2
            exit 2
        }
        check_consistency
        check_pr "$2"
        ;;
    --help | -h) usage ;;
    *)
        usage >&2
        exit 2
        ;;
esac
