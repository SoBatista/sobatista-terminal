#!/usr/bin/env bash

if [ -z "${BASH_VERSION:-}" ]; then
    printf 'ERROR: SoBatista Terminal must be run with Bash: bash install.sh\n' >&2
    exit 2
fi

set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=scripts/lib/install-common.sh
source "$SCRIPT_DIR/scripts/lib/install-common.sh"

ASSUME_YES=0
ALL_MODELS=0
CONFIGS_ONLY=0
DRY_RUN=0
SKIP_OLLAMA=0
SKIP_CODEX=0
SELF_TEST=0
DEFAULT_MODEL='qwen2.5-coder:7b'

usage() {
    cat <<'EOF'
Usage: bash install.sh [OPTIONS]

Install SoBatista Terminal on Debian/Ubuntu/Mint, Fedora, or Arch Linux.

Options:
  --help            Show this help
  --dry-run         Validate and print actions without changing the system
  --yes             Accept package and external-installer confirmations
  --configs-only    Install configuration only; skip packages and software
  --skip-ollama     Do not install Ollama or pull Qwen models
  --skip-codex      Do not install Codex
  --all-models      Pull the supported 7B, 14B, and 30B models
  --self-test       Validate the repository and change nothing

The installer refuses root, backs up every changed target, and never uses
`curl | sh`. External installers are downloaded to a temporary file, identified,
and offered for inspection before execution.
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
            --configs-only) CONFIGS_ONLY=1 ;;
            --skip-ollama) SKIP_OLLAMA=1 ;;
            --skip-codex) SKIP_CODEX=1 ;;
            --all-models) ALL_MODELS=1 ;;
            --self-test) SELF_TEST=1 ;;
            *)
                usage >&2
                printf 'ERROR: Unknown option: %s\n' "$1" >&2
                exit 2
                ;;
        esac
        shift
    done
}

validate_sources() {
    local required
    for required in \
        config/bash/bashrc \
        config/bash/bash_aliases \
        config/bash/inputrc \
        config/starship/starship.toml \
        config/terminator/config \
        config/codex/local-qwen.config.toml.example; do
        [[ -s $SCRIPT_DIR/$required ]] || sb_die "Required file is missing: $required" || return
    done

    bash -n "$SCRIPT_DIR/config/bash/bashrc"
    bash -n "$SCRIPT_DIR/config/bash/bash_aliases"
    bash -n "$SCRIPT_DIR/install.sh"
    bash -n "$SCRIPT_DIR/uninstall.sh"

    if command -v python3 >/dev/null 2>&1; then
        python3 - "$SCRIPT_DIR" <<'PY'
import pathlib
import sys

try:
    import tomllib
except ModuleNotFoundError:
    print(
        "WARNING: Python 3.11+ tomllib is unavailable; skipping structural TOML "
        "validation. The shipped configuration is validated in CI, so this is "
        "safe for an unmodified checkout.",
        file=sys.stderr,
    )
    raise SystemExit(0)

root = pathlib.Path(sys.argv[1])
for relative in (
    "config/starship/starship.toml",
    "config/codex/local-qwen.config.toml.example",
):
    with (root / relative).open("rb") as handle:
        tomllib.load(handle)
PY
    fi

    grep -Fq '[[AI-Workbench]]' "$SCRIPT_DIR/config/terminator/config" \
        || sb_die 'Terminator AI-Workbench layout is missing.'
}

install_packages() {
    local -a packages=()
    case $SB_DISTRO_FAMILY in
        apt)
            packages=(
                bash-completion bat btop curl direnv dnsutils fd-find fontconfig
                fzf git iproute2 jq less man-db nmap openssl pipx ripgrep
                shellcheck terminator tmux unzip xclip zoxide
            )
            sb_run sudo apt-get update
            if ((ASSUME_YES)); then
                sb_run sudo apt-get install -y "${packages[@]}"
            else
                sb_run sudo apt-get install "${packages[@]}"
            fi
            ;;
        dnf5)
            packages=(
                bash-completion bat btop curl direnv bind-utils fd-find fontconfig
                fzf git iproute jq less man-db nmap openssl pipx ripgrep ShellCheck
                terminator tmux unzip xclip zoxide
            )
            if ((ASSUME_YES)); then
                sb_run sudo dnf5 install --refresh -y "${packages[@]}"
            else
                sb_run sudo dnf5 install --refresh "${packages[@]}"
            fi
            ;;
        dnf)
            packages=(
                bash-completion bat btop curl direnv bind-utils fd-find fontconfig
                fzf git iproute jq less man-db nmap openssl pipx ripgrep ShellCheck
                terminator tmux unzip xclip zoxide
            )
            if ((ASSUME_YES)); then
                sb_run sudo dnf install --refresh -y "${packages[@]}"
            else
                sb_run sudo dnf install --refresh "${packages[@]}"
            fi
            ;;
        pacman)
            packages=(
                bash-completion bat btop curl direnv bind fd fontconfig fzf git
                iproute2 jq less man-db nmap openssl python-pipx ripgrep shellcheck
                terminator tmux unzip xclip zoxide
            )
            if ((ASSUME_YES)); then
                sb_run sudo pacman -Syu --needed --noconfirm "${packages[@]}"
            else
                sb_run sudo pacman -Syu --needed "${packages[@]}"
            fi
            ;;
    esac
}

install_tldr() {
    command -v tldr >/dev/null 2>&1 && return 0
    ((DRY_RUN)) && {
        printf '[dry-run] install tldr from the distro, falling back to pipx\n'
        return 0
    }

    sb_note 'Installing tldr'
    local -a yes_args=()
    ((ASSUME_YES)) && yes_args=(-y)
    case $SB_DISTRO_FAMILY in
        apt) sudo apt-get install "${yes_args[@]}" tldr 2>/dev/null && return 0 ;;
        dnf5) sudo dnf5 install "${yes_args[@]}" tealdeer 2>/dev/null && return 0 ;;
        dnf) sudo dnf install "${yes_args[@]}" tealdeer 2>/dev/null && return 0 ;;
        pacman)
            yes_args=()
            ((ASSUME_YES)) && yes_args=(--noconfirm)
            sudo pacman -S --needed "${yes_args[@]}" tealdeer 2>/dev/null && return 0
            ;;
    esac

    command -v pipx >/dev/null 2>&1 || {
        sb_warn 'No distro tldr package and pipx is unavailable; skipping tldr.'
        return 0
    }
    pipx install tldr
}

download_file() {
    local url=$1 destination=$2
    command -v curl >/dev/null 2>&1 || sb_die 'curl is required for external downloads.' || return
    curl -fL --retry 3 --connect-timeout 15 -o "$destination" "$url"
}

run_external_installer() {
    [[ $# -ge 3 ]] || return 2
    local name=$1 url=$2 privilege_note=$3
    shift 3

    printf '\nExternal installer: %s\nSource: %s\nPrivilege behavior: %s\n' \
        "$name" "$url" "$privilege_note"
    if ((DRY_RUN)); then
        printf '[dry-run] download, identify, and offer this installer for inspection\n'
        return 0
    fi
    sb_confirm "Download the official $name installer?" || {
        sb_warn "$name installation skipped by user."
        return 0
    }

    local installer
    installer=$(mktemp "${TMPDIR:-/tmp}/sobatista-installer.XXXXXXXX") || return
    TEMP_FILES+=("$installer")
    download_file "$url" "$installer" || return
    printf 'Downloaded to: %s\nSHA-256: %s\n' "$installer" "$(sb_sha256 "$installer")"
    printf 'Inspect before continuing with: less %q\n' "$installer"
    sb_confirm "Execute the downloaded $name installer now?" || {
        sb_warn "$name installer was downloaded but not executed."
        return 0
    }
    sh "$installer" "$@"
}

install_font() {
    if command -v fc-list >/dev/null 2>&1 \
        && fc-list 2>/dev/null | grep -qi 'JetBrainsMono.*Nerd'; then
        printf 'JetBrainsMono Nerd Font is already installed.\n'
        return
    fi

    local url='https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip'
    local archive="${TMPDIR:-/tmp}/sobatista-jetbrainsmono.$$.zip"
    local destination="$HOME/.local/share/fonts/JetBrainsMonoNerd"
    printf '\nExternal archive: JetBrainsMono Nerd Font\nSource: %s\nDestination: %s\n' \
        "$url" "$destination"
    ((DRY_RUN)) && {
        printf '[dry-run] download and install the user-local font archive\n'
        return 0
    }
    sb_confirm 'Download and install this user-local font?' || return 0
    TEMP_FILES+=("$archive")
    download_file "$url" "$archive" || return
    printf 'Font archive SHA-256: %s\n' "$(sb_sha256 "$archive")"
    mkdir -p -- "$destination"
    unzip -oq "$archive" -d "$destination"
    fc-cache -f
}

install_starship() {
    command -v starship >/dev/null 2>&1 && {
        printf 'Starship already installed: %s\n' "$(starship --version | head -n 1)"
        return
    }
    run_external_installer Starship https://starship.rs/install.sh \
        'Installs only to the requested user-local ~/.local/bin directory.' \
        -b "$HOME/.local/bin" -y
}

install_codex() {
    ((SKIP_CODEX)) && return
    command -v codex >/dev/null 2>&1 && {
        printf 'Codex already installed: %s\n' "$(codex --version 2>/dev/null | head -n 1)"
        return
    }
    run_external_installer Codex https://chatgpt.com/codex/install.sh \
        'Official standalone user installer; review its current behavior before execution.'
}

install_ollama() {
    ((SKIP_OLLAMA)) && return
    if ! command -v ollama >/dev/null 2>&1; then
        run_external_installer Ollama https://ollama.com/install.sh \
            'Official Linux installer may request sudo for its binary and system service.'
    fi
    ((DRY_RUN)) && {
        printf '[dry-run] verify the Ollama loopback API and pull %s%s\n' \
            "$DEFAULT_MODEL" "$([[ $ALL_MODELS == 1 ]] && printf ' plus 14B and 30B')"
        return 0
    }
    command -v ollama >/dev/null 2>&1 || {
        sb_warn 'Ollama is unavailable; model download skipped.'
        return 0
    }

    if ! curl -fsS --max-time 3 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
        sb_warn 'Ollama is installed but its loopback API is stopped.'
        printf 'Start it explicitly, then run: ollama pull %s\n' "$DEFAULT_MODEL"
        return 0
    fi

    local -a models=("$DEFAULT_MODEL")
    ((ALL_MODELS)) && models+=(qwen2.5-coder:14b qwen3-coder:30b)
    local model
    for model in "${models[@]}"; do
        if ollama list | awk 'NR > 1 {print $1}' | grep -Fxq -- "$model"; then
            printf 'Ollama model already installed: %s\n' "$model"
        else
            sb_note "Pulling $model"
            ollama pull "$model"
        fi
    done
}

choose_backup_dir() {
    local stamp candidate counter=0
    stamp=$(date +%Y%m%d-%H%M%S)
    candidate="$BACKUP_ROOT/$stamp"
    while [[ -e $candidate ]]; do
        ((counter += 1))
        candidate="$BACKUP_ROOT/$stamp.$counter"
    done
    printf '%s' "$candidate"
}

install_configs() {
    local backup_dir
    backup_dir=$(choose_backup_dir)
    printf '\nConfiguration backup/rollback location: %s\n' "$backup_dir"

    local -a mappings=(
        "config/bash/bashrc|.bashrc|600"
        "config/bash/bash_aliases|.bash_aliases|600"
        "config/bash/inputrc|.inputrc|600"
        "config/starship/starship.toml|.config/starship.toml|600"
        "config/terminator/config|.config/terminator/config|600"
    )

    if ((DRY_RUN)); then
        local mapping source relative mode target
        for mapping in "${mappings[@]}"; do
            IFS='|' read -r source relative mode <<<"$mapping"
            target="$HOME/$relative"
            if [[ -L $target || -e $target ]] \
                && { [[ -L $target ]] || ! cmp -s "$SCRIPT_DIR/$source" "$target"; }; then
                printf '[dry-run] back up %s to %s/files/%s\n' \
                    "$target" "$backup_dir" "$relative"
            fi
            if [[ ! -L $target && -e $target ]] && cmp -s "$SCRIPT_DIR/$source" "$target"; then
                printf '[dry-run] unchanged %s\n' "$target"
            else
                printf '[dry-run] install %s -> %s (mode %s)\n' "$source" "$target" "$mode"
            fi
        done
        printf '[dry-run] write install manifest: %s\n' "$INSTALL_MANIFEST"
        return 0
    fi

    mkdir -p -- "$backup_dir/files" "$(dirname -- "$INSTALL_MANIFEST")"
    local manifest_tmp="$INSTALL_MANIFEST.tmp.$$"
    TEMP_FILES+=("$manifest_tmp")
    : >"$manifest_tmp"
    printf 'version=%s\ncreated=%s\n' "$(<"$SCRIPT_DIR/VERSION")" "$(date -u +%FT%TZ)" \
        >"$backup_dir/metadata"

    local mapping source relative relative_dir mode target hash
    for mapping in "${mappings[@]}"; do
        IFS='|' read -r source relative mode <<<"$mapping"
        target="$HOME/$relative"
        sb_validate_home_target "$target" || return
        if [[ -L $target || -e $target ]] \
            && { [[ -L $target ]] || ! cmp -s "$SCRIPT_DIR/$source" "$target"; }; then
            relative_dir=$(dirname -- "$relative")
            mkdir -p -- "$backup_dir/files/$relative_dir"
            cp -a -- "$target" "$backup_dir/files/$relative"
            printf '%s\n' "$relative" >>"$backup_dir/restorable-files"
        fi

        if [[ ! -L $target && -e $target ]] && cmp -s "$SCRIPT_DIR/$source" "$target"; then
            printf 'Unchanged: %s\n' "$target"
        else
            sb_atomic_install "$SCRIPT_DIR/$source" "$target" "$mode"
            printf 'Installed: %s\n' "$target"
        fi
        hash=$(sb_sha256 "$target")
        printf '%s\t%s\n' "$relative" "$hash" >>"$manifest_tmp"
    done
    mv -f -- "$manifest_tmp" "$INSTALL_MANIFEST"
    chmod 600 "$INSTALL_MANIFEST"
    printf 'Rollback with: bash uninstall.sh --restore %q\n' "$backup_dir"
}

cleanup() {
    local file
    for file in "${TEMP_FILES[@]:-}"; do
        [[ -n $file ]] && rm -f -- "$file"
    done
    return 0
}

main() {
    parse_args "$@"
    ((EUID != 0)) || {
        printf 'ERROR: Refusing to run as root. Run as your normal desktop user.\n' >&2
        exit 1
    }

    validate_sources
    if ((SELF_TEST)); then
        exec "$SCRIPT_DIR/scripts/self-test.sh" --portable
    fi

    STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}/sobatista-terminal
    BACKUP_ROOT=$STATE_HOME/backups
    INSTALL_MANIFEST=$STATE_HOME/install-manifest.tsv
    TEMP_FILES=()
    trap cleanup EXIT INT TERM

    if ((!CONFIGS_ONLY)); then
        sb_detect_distro "${SOBATISTA_OS_RELEASE_FILE:-/etc/os-release}"
        printf 'Detected: %s (%s package family)\n' "$SB_DISTRO_ID" "$SB_DISTRO_FAMILY"
        sb_confirm 'Install distribution packages?' || {
            sb_warn 'Package installation skipped by user.'
            CONFIGS_ONLY=1
        }
    fi

    if ((!CONFIGS_ONLY)); then
        install_packages
        install_tldr
        install_font
        install_starship
        install_codex
        install_ollama
    fi

    install_configs
    sb_note 'SoBatista Terminal installation complete'
    printf 'Open a new Bash shell, then run: termhelp\n'
    printf 'Diagnostics: llm_check    Layout: terminator -l AI-Workbench\n'
}

main "$@"
