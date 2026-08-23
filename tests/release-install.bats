#!/usr/bin/env bats

# Installation from a *release-shaped* source tree.
#
# The other installer tests run install.sh straight out of the working
# directory, which also holds .git, ignored scratch files, and whatever else the
# checkout happens to contain. A published release is a different shape: the
# GitHub source archive for a tag — identical to `git archive` of that tag —
# contains only the committed, tracked files under a `NAME-VERSION/` prefix,
# with no .git and no surrounding repository state. Every test here installs
# from exactly that shape.
#
# Honest limitation: a pull request cannot install from its own tag, because the
# release workflow only creates `vX.Y.Z` after that pull request is merged. By
# default this file therefore builds the release shape from the tracked files
# under test (identical to the archive of the commit in a clean CI checkout).
# Set SOBATISTA_RELEASE_REF to a published tag to archive that tag instead.
# Verification against a genuinely downloaded release tarball is a separate,
# manual post-release job: .github/workflows/release-verify.yml. Nothing in this
# file asserts that GitHub was contacted.

load helpers/test_helper

setup() {
    make_test_home
    command -v git >/dev/null 2>&1 || skip 'git is required to build a release-shaped tree'
    git -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1 \
        || skip 'not a Git checkout; cannot build a release-shaped tree'

    SOURCE_TREE="$BATS_TEST_TMPDIR/source"
    RELEASE_REF=${SOBATISTA_RELEASE_REF:-}
    if [[ -n $RELEASE_REF ]]; then
        RELEASE_VERSION=$(git -C "$REPO_ROOT" show "$RELEASE_REF:VERSION")
        RELEASE_VERSION=${RELEASE_VERSION%%$'\n'*}
        RELEASE_ROOT="$SOURCE_TREE/sobatista-terminal-$RELEASE_VERSION"
        mkdir -p "$SOURCE_TREE"
        git -C "$REPO_ROOT" archive --format=tar \
            --prefix="sobatista-terminal-$RELEASE_VERSION/" "$RELEASE_REF" \
            | tar -x -C "$SOURCE_TREE"
    else
        IFS= read -r RELEASE_VERSION <"$REPO_ROOT/VERSION"
        RELEASE_ROOT="$SOURCE_TREE/sobatista-terminal-$RELEASE_VERSION"
        mkdir -p "$RELEASE_ROOT"
        # Tracked files only, straight from the tree under test, so an
        # uncommitted change is validated instead of silently skipped.
        git -C "$REPO_ROOT" ls-files -z \
            | tar -C "$REPO_ROOT" -cf - --null --no-recursion -T - \
            | tar -xf - -C "$RELEASE_ROOT"
    fi

    export RELEASE_ROOT RELEASE_VERSION
}

release_install() {
    env HOME="$TEST_HOME" XDG_STATE_HOME="$TEST_STATE" \
        bash "$RELEASE_ROOT/install.sh" "$@"
}

release_uninstall() {
    env HOME="$TEST_HOME" XDG_STATE_HOME="$TEST_STATE" \
        bash "$RELEASE_ROOT/uninstall.sh" "$@"
}

@test "the release-shaped tree is exactly the tracked files, with no .git" {
    [ -d "$RELEASE_ROOT" ]
    [ ! -e "$RELEASE_ROOT/.git" ]
    [ -x "$RELEASE_ROOT/install.sh" ]
    [ -x "$RELEASE_ROOT/uninstall.sh" ]
    [ -s "$RELEASE_ROOT/VERSION" ]

    expected="$BATS_TEST_TMPDIR/expected-files"
    actual="$BATS_TEST_TMPDIR/actual-files"
    if [[ -n $RELEASE_REF ]]; then
        git -C "$REPO_ROOT" ls-tree -r --name-only "$RELEASE_REF" | sort >"$expected"
    else
        git -C "$REPO_ROOT" ls-files | sort >"$expected"
    fi
    (cd "$RELEASE_ROOT" && find . -type f -printf '%P\n') | sort >"$actual"
    run diff -u "$expected" "$actual"
    [ "$status" -eq 0 ]
}

@test "release-shaped tree self-tests and dry-runs without touching the temporary HOME" {
    command -v rg >/dev/null 2>&1 || skip 'ripgrep is required by the portable self-test'
    run release_install --self-test
    [ "$status" -eq 0 ]

    run release_install --configs-only --dry-run --yes
    [ "$status" -eq 0 ]
    [[ $output == *'[dry-run]'* ]]
    [ ! -e "$TEST_HOME/.bashrc" ]
    [ ! -e "$TEST_STATE/sobatista-terminal/install-manifest.tsv" ]
}

@test "configs-only install from a release-shaped tree writes every documented target" {
    run release_install --configs-only --yes
    [ "$status" -eq 0 ]

    # The five documented installation targets, in docs/installation.md order.
    for relative in .bashrc .bash_aliases .inputrc \
        .config/starship.toml .config/terminator/config; do
        [ -s "$TEST_HOME/$relative" ]
        [ ! -L "$TEST_HOME/$relative" ]
        run stat -c '%a' "$TEST_HOME/$relative"
        [ "$output" = '600' ]
    done

    run cmp -s "$RELEASE_ROOT/config/bash/bashrc" "$TEST_HOME/.bashrc"
    [ "$status" -eq 0 ]
    run cmp -s "$RELEASE_ROOT/config/bash/inputrc" "$TEST_HOME/.inputrc"
    [ "$status" -eq 0 ]
    run cmp -s "$RELEASE_ROOT/config/starship/starship.toml" "$TEST_HOME/.config/starship.toml"
    [ "$status" -eq 0 ]
    run cmp -s "$RELEASE_ROOT/config/terminator/config" "$TEST_HOME/.config/terminator/config"
    [ "$status" -eq 0 ]
    run grep -Fq '[[AI-Workbench]]' "$TEST_HOME/.config/terminator/config"
    [ "$status" -eq 0 ]

    manifest="$TEST_STATE/sobatista-terminal/install-manifest.tsv"
    [ -s "$manifest" ]
    run grep -c '' "$manifest"
    [ "$output" = '5' ]
}

@test "installed Starship configuration parses and renders the safe capture identity" {
    command -v python3 >/dev/null 2>&1 || skip 'python3 is unavailable'
    python3 -c 'import tomllib' 2>/dev/null || skip 'Python 3.11+ tomllib is unavailable'
    command -v starship >/dev/null 2>&1 || skip 'starship is not installed'

    run release_install --configs-only --yes
    [ "$status" -eq 0 ]

    run python3 -c 'import sys, tomllib; tomllib.load(open(sys.argv[1], "rb"))' \
        "$TEST_HOME/.config/starship.toml"
    [ "$status" -eq 0 ]

    run env HOME="$TEST_HOME" \
        STARSHIP_CONFIG="$TEST_HOME/.config/starship.toml" \
        SOBATISTA_PROMPT_IDENTITY='sobatista@blackice' \
        starship prompt --status=0
    [ "$status" -eq 0 ]
    [[ $output == *'sobatista@blackice'* ]]
}

@test "installed Terminator configuration parses under Terminator's own parser" {
    command -v python3 >/dev/null 2>&1 || skip 'python3 is unavailable'
    python3 -c 'import configobj' 2>/dev/null || skip 'python3-configobj is unavailable'

    run release_install --configs-only --yes
    [ "$status" -eq 0 ]

    run python3 -c '
import sys
from configobj import ConfigObj

config = ConfigObj(sys.argv[1], list_values=False)
assert config["profiles"]["default"]["background_darkness"] == "0.90"
assert config["profiles"]["default"]["background_type"] == "transparent"
assert config["profiles"]["BlackIce-Solid"]["background_type"] == "solid"
assert "AI-Workbench" in config["layouts"]
' "$TEST_HOME/.config/terminator/config"
    [ "$status" -eq 0 ]
}

@test "a clean interactive Bash shell loads the release install and resolves public commands" {
    run release_install --configs-only --yes
    [ "$status" -eq 0 ]

    run bash -n "$TEST_HOME/.bashrc" "$TEST_HOME/.bash_aliases"
    [ "$status" -eq 0 ]

    # --rcfile loads the *installed* .bashrc (which sources .bash_aliases);
    # --norc would disable exactly what this checks. env -i drops the Bats
    # environment so the shell starts from the installed configuration alone,
    # and TERM=dumb keeps the fallback prompt free of escape sequences.
    run env -i HOME="$TEST_HOME" PATH="$PATH" TERM=dumb \
        bash --noprofile --rcfile "$TEST_HOME/.bashrc" -ic '
            status=0
            for name in termhelp cmdhelp termreload termdev_status privacy \
                qmodel qm q llm_check mkcd croot; do
                [[ $(type -t "$name") == function ]] \
                    || { printf "not a function: %s\n" "$name" >&2; status=1; }
            done
            for name in g gst gup ll workbench th ch; do
                alias "$name" >/dev/null 2>&1 \
                    || { printf "missing alias: %s\n" "$name" >&2; status=1; }
            done
            termhelp dev >/dev/null || status=1
            termhelp privacy >/dev/null || status=1
            ((status == 0)) && printf "interactive-shell-ok\n"
            exit "$status"
        '
    [ "$status" -eq 0 ]
    [[ $output == *'interactive-shell-ok'* ]]
}

@test "uninstall removes the release install and rollback restores the previous files" {
    printf 'pre-existing bashrc\n' >"$TEST_HOME/.bashrc"
    printf 'pre-existing inputrc\n' >"$TEST_HOME/.inputrc"

    run release_install --configs-only --yes
    [ "$status" -eq 0 ]
    run cat "$TEST_HOME/.bashrc"
    [ "$output" != 'pre-existing bashrc' ]

    backup=$(find "$TEST_STATE/sobatista-terminal/backups" -mindepth 1 -maxdepth 1 -type d \
        | sort | head -n 1)
    [ -n "$backup" ]
    run grep -Fx "version=$RELEASE_VERSION" "$backup/metadata"
    [ "$status" -eq 0 ]

    run release_uninstall --yes --restore "$backup"
    [ "$status" -eq 0 ]
    run cat "$TEST_HOME/.bashrc"
    [ "$output" = 'pre-existing bashrc' ]
    run cat "$TEST_HOME/.inputrc"
    [ "$output" = 'pre-existing inputrc' ]
    [ -d "$TEST_STATE/sobatista-terminal/backups" ]

    # Reinstalling and then uninstalling without a restore removes only files
    # that still match the manifest, leaving nothing of the release install.
    run release_install --configs-only --yes
    [ "$status" -eq 0 ]
    run release_uninstall --yes
    [ "$status" -eq 0 ]
    for relative in .bashrc .bash_aliases .inputrc \
        .config/starship.toml .config/terminator/config; do
        [ ! -e "$TEST_HOME/$relative" ]
    done
    [ ! -e "$TEST_STATE/sobatista-terminal/install-manifest.tsv" ]
}

@test "the release install records no path outside the temporary HOME and state root" {
    [ -n "$HOME" ]
    [ "$HOME" != '/' ]
    [ "$HOME" != "$TEST_HOME" ]

    run release_install --configs-only --yes
    [ "$status" -eq 0 ]
    [ -d "$TEST_STATE/sobatista-terminal" ]

    # Nothing the installer wrote may reference the real HOME of whoever ran the
    # suite, and the real HOME must be untouched by this test.
    run grep -rlF "$HOME/" "$TEST_STATE/sobatista-terminal"
    [ "$status" -ne 0 ]
    run grep -rlF "$HOME/" "$TEST_HOME/.bashrc" "$TEST_HOME/.bash_aliases"
    [ "$status" -ne 0 ]
}
