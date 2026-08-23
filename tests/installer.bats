#!/usr/bin/env bats

load helpers/test_helper

setup() {
    make_test_home
}

@test "installer help documents all public options" {
    run bash "$REPO_ROOT/install.sh" --help
    [ "$status" -eq 0 ]
    for option in --dry-run --yes --configs-only --skip-ollama --skip-codex --all-models --self-test; do
        [[ $output == *"$option"* ]]
    done
}

@test "unknown installer arguments fail clearly" {
    run bash "$REPO_ROOT/install.sh" --not-an-option
    [ "$status" -eq 2 ]
    [[ $output == *'Unknown option'* ]]
}

@test "dry run changes nothing in a temporary HOME" {
    run env HOME="$TEST_HOME" XDG_STATE_HOME="$TEST_STATE" \
        bash "$REPO_ROOT/install.sh" --configs-only --dry-run --yes
    [ "$status" -eq 0 ]
    [[ $output == *'[dry-run]'* ]]
    [ ! -e "$TEST_HOME/.bashrc" ]
    [ ! -e "$TEST_STATE/sobatista-terminal/install-manifest.tsv" ]
}

@test "temporary-HOME install creates configs and a manifest" {
    run env HOME="$TEST_HOME" XDG_STATE_HOME="$TEST_STATE" \
        bash "$REPO_ROOT/install.sh" --configs-only --yes
    [ "$status" -eq 0 ]
    [ -s "$TEST_HOME/.bashrc" ]
    [ -s "$TEST_HOME/.config/starship.toml" ]
    [ -s "$TEST_HOME/.config/terminator/config" ]
    [ -s "$TEST_STATE/sobatista-terminal/install-manifest.tsv" ]
}

@test "changed existing config is backed up" {
    printf 'original bashrc\n' > "$TEST_HOME/.bashrc"
    run env HOME="$TEST_HOME" XDG_STATE_HOME="$TEST_STATE" \
        bash "$REPO_ROOT/install.sh" --configs-only --yes
    [ "$status" -eq 0 ]
    backup_root="$TEST_STATE/sobatista-terminal/backups"
    backup=$(find "$backup_root" -mindepth 1 -maxdepth 1 -type d | head -n 1)
    [ -n "$backup" ]
    run cat "$backup/files/.bashrc"
    [ "$output" = 'original bashrc' ]
}

@test "installer replaces a target symlink without overwriting its referent" {
    local referent="$BATS_TEST_TMPDIR/original-bashrc"
    printf 'symlink referent data\n' > "$referent"
    ln -s "$referent" "$TEST_HOME/.bashrc"

    run env HOME="$TEST_HOME" XDG_STATE_HOME="$TEST_STATE" \
        bash "$REPO_ROOT/install.sh" --configs-only --yes
    [ "$status" -eq 0 ]
    [ ! -L "$TEST_HOME/.bashrc" ]
    run cat "$referent"
    [ "$output" = 'symlink referent data' ]
    backup=$(find "$TEST_STATE/sobatista-terminal/backups" -mindepth 1 -maxdepth 1 -type d | head -n 1)
    [ -L "$backup/files/.bashrc" ]
}

@test "rollback restores selected backup" {
    printf 'original bashrc\n' > "$TEST_HOME/.bashrc"
    run env HOME="$TEST_HOME" XDG_STATE_HOME="$TEST_STATE" \
        bash "$REPO_ROOT/install.sh" --configs-only --yes
    [ "$status" -eq 0 ]
    backup=$(find "$TEST_STATE/sobatista-terminal/backups" -mindepth 1 -maxdepth 1 -type d | head -n 1)

    run env HOME="$TEST_HOME" XDG_STATE_HOME="$TEST_STATE" \
        bash "$REPO_ROOT/uninstall.sh" --yes --restore "$backup"
    [ "$status" -eq 0 ]
    run cat "$TEST_HOME/.bashrc"
    [ "$output" = 'original bashrc' ]
    [ -d "$TEST_STATE/sobatista-terminal/backups" ]
}

@test "uninstall preserves a user-modified installed file" {
    run env HOME="$TEST_HOME" XDG_STATE_HOME="$TEST_STATE" \
        bash "$REPO_ROOT/install.sh" --configs-only --yes
    [ "$status" -eq 0 ]
    printf '\n# local user edit\n' >> "$TEST_HOME/.bashrc"
    run env HOME="$TEST_HOME" XDG_STATE_HOME="$TEST_STATE" \
        bash "$REPO_ROOT/uninstall.sh" --yes
    [ "$status" -eq 0 ]
    [ -e "$TEST_HOME/.bashrc" ]
    [[ $output == *'Preserved modified file'* ]]
}

@test "distro detection maps supported families and rejects unsupported IDs" {
    local mocks="$BATS_TEST_TMPDIR/pkg-bin"
    mkdir -p "$mocks"
    for command_name in apt-get dnf dnf5 pacman; do
        printf '#!/usr/bin/env bash\nexit 0\n' > "$mocks/$command_name"
        chmod +x "$mocks/$command_name"
    done

    printf 'ID=ubuntu\nID_LIKE=debian\n' > "$BATS_TEST_TMPDIR/os-release"
    run env PATH="$mocks:/usr/bin:/bin" REPO_ROOT="$REPO_ROOT" OS_FILE="$BATS_TEST_TMPDIR/os-release" \
        bash -c 'source "$REPO_ROOT/scripts/lib/install-common.sh"; sb_detect_distro "$OS_FILE"; printf "%s" "$SB_DISTRO_FAMILY"'
    [ "$status" -eq 0 ]
    [ "$output" = 'apt' ]

    printf 'ID=fedora\n' > "$BATS_TEST_TMPDIR/os-release"
    run env PATH="$mocks:/usr/bin:/bin" REPO_ROOT="$REPO_ROOT" OS_FILE="$BATS_TEST_TMPDIR/os-release" \
        bash -c 'source "$REPO_ROOT/scripts/lib/install-common.sh"; sb_detect_distro "$OS_FILE"; printf "%s" "$SB_DISTRO_FAMILY"'
    [ "$status" -eq 0 ]
    [ "$output" = 'dnf5' ]

    printf 'ID=arch\n' > "$BATS_TEST_TMPDIR/os-release"
    run env PATH="$mocks:/usr/bin:/bin" REPO_ROOT="$REPO_ROOT" OS_FILE="$BATS_TEST_TMPDIR/os-release" \
        bash -c 'source "$REPO_ROOT/scripts/lib/install-common.sh"; sb_detect_distro "$OS_FILE"; printf "%s" "$SB_DISTRO_FAMILY"'
    [ "$status" -eq 0 ]
    [ "$output" = 'pacman' ]

    printf 'ID=opensuse-tumbleweed\n' > "$BATS_TEST_TMPDIR/os-release"
    run env PATH="$mocks:/usr/bin:/bin" REPO_ROOT="$REPO_ROOT" OS_FILE="$BATS_TEST_TMPDIR/os-release" \
        bash -c 'source "$REPO_ROOT/scripts/lib/install-common.sh"; sb_detect_distro "$OS_FILE"'
    [ "$status" -ne 0 ]
    [[ $output == *'Unsupported distribution'* ]]
}
