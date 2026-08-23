REPO_ROOT=$(cd -- "$BATS_TEST_DIRNAME/.." && pwd -P)

make_test_home() {
    TEST_HOME=$(mktemp -d "${BATS_TEST_TMPDIR}/home.XXXXXXXX")
    TEST_STATE=$(mktemp -d "${BATS_TEST_TMPDIR}/state.XXXXXXXX")
    export TEST_HOME TEST_STATE REPO_ROOT
}

install_test_shell_files() {
    install -D -m 600 "$REPO_ROOT/config/bash/bashrc" "$TEST_HOME/.bashrc"
    install -D -m 600 "$REPO_ROOT/config/bash/bash_aliases" "$TEST_HOME/.bash_aliases"
}

make_mock() {
    local name=$1 body=$2
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    printf '#!/usr/bin/env bash\n%s\n' "$body" > "$BATS_TEST_TMPDIR/bin/$name"
    chmod +x "$BATS_TEST_TMPDIR/bin/$name"
}
