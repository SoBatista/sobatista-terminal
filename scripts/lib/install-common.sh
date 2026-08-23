#!/usr/bin/env bash

# Shared installer helpers. This file is sourced by install.sh, uninstall.sh,
# and distro-detection tests; it does not change the system when sourced.

sb_note() {
    printf '\n==> %s\n' "$*"
}

sb_warn() {
    printf 'WARNING: %s\n' "$*" >&2
}

sb_die() {
    printf 'ERROR: %s\n' "$*" >&2
    return 1
}

sb_shell_join() {
    local item rendered=''
    for item in "$@"; do
        printf -v item '%q' "$item"
        rendered+="${rendered:+ }$item"
    done
    printf '%s' "$rendered"
}

sb_run() {
    if [[ ${DRY_RUN:-0} == 1 ]]; then
        printf '[dry-run] %s\n' "$(sb_shell_join "$@")"
        return 0
    fi
    "$@"
}

sb_confirm() {
    [[ ${ASSUME_YES:-0} == 1 ]] && return 0
    local answer
    printf '%s [y/N] ' "$1"
    IFS= read -r answer
    [[ $answer == [yY] || $answer == [yY][eE][sS] ]]
}

sb_os_value() {
    local key=$1 file=$2
    awk -F= -v wanted="$key" '
        $1 == wanted {
            value = substr($0, index($0, "=") + 1)
            gsub(/^"|"$/, "", value)
            print tolower(value)
            exit
        }
    ' "$file"
}

sb_detect_distro() {
    local os_file=${1:-/etc/os-release}
    [[ -r $os_file ]] || sb_die "Cannot read distribution metadata: $os_file" || return

    SB_DISTRO_ID=$(sb_os_value ID "$os_file")
    SB_DISTRO_LIKE=$(sb_os_value ID_LIKE "$os_file")

    case " $SB_DISTRO_ID $SB_DISTRO_LIKE " in
        *' debian '* | *' ubuntu '*) SB_DISTRO_FAMILY=apt ;;
        *' fedora '*)
            if command -v dnf5 >/dev/null 2>&1; then
                SB_DISTRO_FAMILY=dnf5
            else
                SB_DISTRO_FAMILY=dnf
            fi
            ;;
        *' arch '*) SB_DISTRO_FAMILY=pacman ;;
        *)
            sb_die "Unsupported distribution '$SB_DISTRO_ID'. Supported: Debian/Ubuntu/Mint, Fedora, and Arch."
            return
            ;;
    esac

    if [[ -n ${SOBATISTA_PACKAGE_MANAGER:-} ]]; then
        case $SOBATISTA_PACKAGE_MANAGER in
            apt | dnf | dnf5 | pacman) SB_DISTRO_FAMILY=$SOBATISTA_PACKAGE_MANAGER ;;
            *) sb_die "Invalid SOBATISTA_PACKAGE_MANAGER override" || return ;;
        esac
    fi

    case $SB_DISTRO_FAMILY in
        apt) command -v apt-get >/dev/null 2>&1 || sb_die 'apt-get is required for this distribution.' ;;
        dnf5) command -v dnf5 >/dev/null 2>&1 || sb_die 'dnf5 is required for this distribution.' ;;
        dnf) command -v dnf >/dev/null 2>&1 || sb_die 'dnf is required for this distribution.' ;;
        pacman) command -v pacman >/dev/null 2>&1 || sb_die 'pacman is required for this distribution.' ;;
    esac
}

sb_sha256() {
    sha256sum "$1" | awk '{print $1}'
}

sb_target_allowed() {
    case ${1:-} in
        .bashrc | .bash_aliases | .inputrc | .config/starship.toml | .config/terminator/config)
            return 0
            ;;
        *) return 1 ;;
    esac
}

sb_mode_for_target() {
    case ${1:-} in
        .bashrc | .bash_aliases | .inputrc) printf '600' ;;
        .config/starship.toml | .config/terminator/config) printf '600' ;;
        *) return 1 ;;
    esac
}

sb_validate_home_target() {
    local target=$1 parent home_resolved parent_resolved
    [[ $target == "$HOME"/* ]] || sb_die "Target is outside HOME: $target" || return
    parent=$(dirname -- "$target")
    home_resolved=$(realpath -m -- "$HOME")
    parent_resolved=$(realpath -m -- "$parent")
    [[ $parent_resolved == "$home_resolved" || $parent_resolved == "$home_resolved"/* ]] \
        || sb_die "Target parent resolves outside HOME: $target" || return
}

sb_atomic_install() {
    local source=$1 target=$2 mode=$3
    local temporary="$target.sobatista-tmp.$$"
    sb_validate_home_target "$target" || return
    mkdir -p -- "$(dirname -- "$target")"
    install -m "$mode" "$source" "$temporary"
    mv -Tf -- "$temporary" "$target"
}

sb_atomic_symlink() {
    local link_target=$1 target=$2
    local temporary="$target.sobatista-tmp.$$"
    sb_validate_home_target "$target" || return
    mkdir -p -- "$(dirname -- "$target")"
    ln -s -- "$link_target" "$temporary"
    mv -Tf -- "$temporary" "$target"
}
