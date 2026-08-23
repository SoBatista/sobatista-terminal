#!/usr/bin/env bash

if [ -z "${BASH_VERSION:-}" ]; then
    printf 'ERROR: SoBatista Terminal must be run with Bash: bash uninstall.sh\n' >&2
    exit 2
fi

set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=scripts/lib/install-common.sh
source "$SCRIPT_DIR/scripts/lib/install-common.sh"

ASSUME_YES=0
DRY_RUN=0
RESTORE_BACKUP=''
LIST_BACKUPS=0

usage() {
    cat <<'EOF'
Usage: bash uninstall.sh [OPTIONS]

Remove only unchanged files recorded by SoBatista Terminal. Modified files are
preserved. A selected installer backup can be restored in the same operation.

Options:
  --help              Show this help
  --dry-run           Print actions without changing files
  --yes               Skip the confirmation prompt
  --list-backups      List available rollback backups
  --restore BACKUP    Restore a backup directory or backup timestamp
EOF
}

parse_args() {
    while (($#)); do
        case $1 in
            --help | -h)
                usage
                exit 0
                ;;
            --dry-run) DRY_RUN=1 ;;
            --yes) ASSUME_YES=1 ;;
            --list-backups) LIST_BACKUPS=1 ;;
            --restore)
                [[ $# -ge 2 ]] || {
                    printf 'ERROR: --restore requires a backup path or timestamp.\n' >&2
                    exit 2
                }
                RESTORE_BACKUP=$2
                shift
                ;;
            *)
                usage >&2
                printf 'ERROR: Unknown option: %s\n' "$1" >&2
                exit 2
                ;;
        esac
        shift
    done
}

resolve_backup() {
    local requested=$1 candidate resolved root_resolved
    if [[ $requested == /* ]]; then
        candidate=$requested
    else
        candidate="$BACKUP_ROOT/$requested"
    fi
    resolved=$(realpath -m -- "$candidate")
    root_resolved=$(realpath -m -- "$BACKUP_ROOT")
    [[ $resolved == "$root_resolved"/* && -f $resolved/metadata ]] \
        || sb_die "Not a valid SoBatista Terminal backup: $requested" || return
    printf '%s' "$resolved"
}

list_backups() {
    printf 'Available backups in %s:\n' "$BACKUP_ROOT"
    if [[ ! -d $BACKUP_ROOT ]]; then
        printf '  (none)\n'
        return
    fi
    local backup found=0
    for backup in "$BACKUP_ROOT"/*; do
        [[ -f $backup/metadata ]] || continue
        found=1
        printf '  %s\n' "${backup##*/}"
    done
    ((found)) || printf '  (none)\n'
}

preserve_current() {
    local relative=$1
    local target=$HOME/$relative
    [[ -e $target || -L $target ]] || return 0
    if ((DRY_RUN)); then
        printf '[dry-run] preserve current %s -> %s/%s\n' \
            "$target" "$PRESERVE_DIR" "$relative"
        return 0
    fi
    mkdir -p -- "$PRESERVE_DIR/$(dirname -- "$relative")"
    cp -a -- "$target" "$PRESERVE_DIR/$relative"
}

restore_one() {
    local relative=$1 backup=$2
    local source=$backup/files/$relative target=$HOME/$relative
    [[ -e $source || -L $source ]] || return 1
    preserve_current "$relative"
    if ((DRY_RUN)); then
        printf '[dry-run] restore %s -> %s\n' "$source" "$target"
    else
        if [[ -L $source ]]; then
            local temporary="$target.sobatista-tmp.$$"
            sb_validate_home_target "$target" || return
            mkdir -p -- "$(dirname -- "$target")"
            ln -s -- "$(readlink -- "$source")" "$temporary"
            mv -Tf -- "$temporary" "$target"
        elif [[ -f $source ]]; then
            sb_atomic_install "$source" "$target" "$(sb_mode_for_target "$relative")"
        else
            sb_warn "Backup target is neither a regular file nor a symlink: $source"
            return 1
        fi
        printf 'Restored: %s\n' "$target"
    fi
}

remove_or_preserve() {
    local relative=$1 installed_hash=$2
    local target=$HOME/$relative
    [[ -e $target || -L $target ]] || return 0
    if [[ -L $target || ! -f $target ]]; then
        printf 'Preserved modified file type: %s\n' "$target"
        return 0
    fi
    local current_hash
    current_hash=$(sb_sha256 "$target")
    if [[ $current_hash != "$installed_hash" ]]; then
        printf 'Preserved modified file: %s\n' "$target"
        return 0
    fi
    if ((DRY_RUN)); then
        printf '[dry-run] remove unchanged project file: %s\n' "$target"
    else
        rm -f -- "$target"
        printf 'Removed: %s\n' "$target"
    fi
}

main() {
    parse_args "$@"
    ((EUID != 0)) || {
        printf 'ERROR: Refusing to run as root. Run as your normal desktop user.\n' >&2
        exit 1
    }

    STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}/sobatista-terminal
    BACKUP_ROOT=$STATE_HOME/backups
    INSTALL_MANIFEST=$STATE_HOME/install-manifest.tsv
    PRESERVE_DIR=$STATE_HOME/uninstall-preserved/$(date +%Y%m%d-%H%M%S)

    if ((LIST_BACKUPS)); then
        list_backups
        [[ -z $RESTORE_BACKUP ]] && exit 0
    fi
    [[ -f $INSTALL_MANIFEST ]] || {
        printf 'ERROR: Install manifest not found: %s\nNothing was removed.\n' \
            "$INSTALL_MANIFEST" >&2
        exit 1
    }

    local backup=''
    if [[ -n $RESTORE_BACKUP ]]; then
        backup=$(resolve_backup "$RESTORE_BACKUP") || exit
        printf 'Selected rollback backup: %s\n' "$backup"
    fi

    sb_confirm 'Remove recorded SoBatista Terminal files and apply the selected restore?' || {
        printf 'Cancelled; no files changed.\n'
        exit 0
    }

    local relative installed_hash
    while IFS=$'\t' read -r relative installed_hash; do
        [[ -n $relative && -n $installed_hash ]] || continue
        sb_target_allowed "$relative" || {
            sb_warn "Ignoring unexpected manifest target: $relative"
            continue
        }
        if [[ -n $backup ]] && restore_one "$relative" "$backup"; then
            :
        else
            remove_or_preserve "$relative" "$installed_hash"
        fi
    done <"$INSTALL_MANIFEST"

    if ((!DRY_RUN)); then
        local record
        record=$STATE_HOME/uninstalled-manifest-$(date +%Y%m%d-%H%M%S).tsv
        mv -- "$INSTALL_MANIFEST" "$record"
        printf 'Uninstall record retained at: %s\n' "$record"
    fi
    [[ -d $PRESERVE_DIR ]] && printf 'Pre-restore files preserved at: %s\n' "$PRESERVE_DIR"
    printf 'Backups were not deleted: %s\n' "$BACKUP_ROOT"
}

main "$@"
