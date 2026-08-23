#!/usr/bin/env bats

load helpers/test_helper

# check-version.sh derives its repository root from its own location, so a
# throwaway layout lets these tests exercise it against crafted metadata
# without touching the real VERSION/CHANGELOG/README.
setup() {
    make_test_home
    FAKE=$(mktemp -d "${BATS_TEST_TMPDIR}/repo.XXXXXXXX")
    mkdir -p "$FAKE/scripts"
    cp "$REPO_ROOT/scripts/check-version.sh" "$FAKE/scripts/check-version.sh"
}

write_consistent_repo() {
    local version=$1 trailing=$2
    if [[ $trailing == with-newline ]]; then
        printf '%s\n' "$version" >"$FAKE/VERSION"
    else
        printf '%s' "$version" >"$FAKE/VERSION"
    fi
    printf '## [%s] - 2026-08-23\n' "$version" >"$FAKE/CHANGELOG.md"
    printf 'Version: `%s`\n' "$version" >"$FAKE/README.md"
}

@test "consistency accepts a single-line VERSION without a trailing newline" {
    write_consistent_repo 1.2.3 no-newline
    run "$FAKE/scripts/check-version.sh" --consistency
    [ "$status" -eq 0 ]
    [[ $output == *'1.2.3'* ]]
}

@test "consistency rejects a multi-line VERSION" {
    write_consistent_repo 1.2.3 with-newline
    printf '1.2.3\nextra\n' >"$FAKE/VERSION"
    run "$FAKE/scripts/check-version.sh" --consistency
    [ "$status" -ne 0 ]
    [[ $output == *'exactly one line'* ]]
}

@test "PR validation fails loudly on an unfetched base ref" {
    write_consistent_repo 0.1.0 with-newline
    (
        cd "$FAKE"
        git init -q
        git add -A
        git -c user.email=t@example.com -c user.name=test commit -qm init
    )
    run env RELEASE_LABELS='release:patch' \
        "$FAKE/scripts/check-version.sh" --pr origin/does-not-exist
    [ "$status" -ne 0 ]
    [[ $output == *'Base ref not found'* ]]
}
