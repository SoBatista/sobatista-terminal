# Installation

## Safety model

`install.sh` must run as a normal user under Bash. It refuses root and invokes
`sudo` directly only for explicit package-manager operations. The official
Ollama installer is an external boundary and may itself request `sudo`; the
installer explains that before download.

Configuration targets are compared before replacement. Changed files are copied
with metadata to a timestamped XDG state directory. An installation manifest
records the SHA-256 of every installed target so uninstall can distinguish an
unchanged project file from a later user edit.

The installer never deletes an existing user file, never reads Codex auth or
session state, and never uses `curl | sh`.

## Inspect, validate, and install

```bash
git clone https://github.com/SoBatista/sobatista-terminal.git
cd sobatista-terminal
git log -1 --oneline
less install.sh
bash install.sh --self-test
bash install.sh --dry-run
bash install.sh
```

Options:

| Option | Effect |
| --- | --- |
| `--help` | Print usage and exit. |
| `--dry-run` | Validate inputs and print exact actions without writes, `sudo`, or downloads. |
| `--yes` | Accept package-manager and external-installer confirmation prompts. |
| `--configs-only` | Install only the five configuration targets. |
| `--skip-ollama` | Skip the Ollama installer and model pull. |
| `--skip-codex` | Skip the Codex installer. |
| `--all-models` | Pull 7B, 14B, and 30B defaults; without it only 7B is pulled. |
| `--self-test` | Run portable syntax, TOML, version, secret, and presence checks; change nothing. |

`--all-models` may consume tens of gigabytes depending on Ollama manifests and
quantization. The installer does not use a hard-coded size claim because model
artifacts change.

## Distribution package maps

The installer reads `/etc/os-release` and then requires the matching package
manager. It accepts only Debian/Ubuntu/Mint, Fedora, and Arch family identifiers.
An unrelated distribution that happens to ship one of these managers is rejected.

Core capabilities installed through the distribution include Bash completion,
Git, curl, jq, ripgrep, fzf, zoxide, direnv, networking/TLS tools, Nmap,
Terminator, ShellCheck, pipx, font tools, archive tools, and system inspection
utilities. Package names are mapped for APT, DNF/DNF5, and pacman.

`tldr` is attempted through the distribution first. If no usable distribution
package exists, it is installed through pipx. Optional visual tools are not
required for the configuration to load.

## External software

These sources are announced before use:

- JetBrainsMono Nerd Font archive from the Nerd Fonts GitHub release page.
- Starship's official installer at `https://starship.rs/install.sh`.
- Codex's official installer at `https://chatgpt.com/codex/install.sh`.
- Ollama's official installer at `https://ollama.com/install.sh`.

Each installer is downloaded to a named temporary file. Its path and SHA-256 are
printed, and an interactive run pauses so the file can be inspected from another
terminal. `--yes` is appropriate only for reviewed automation.

An inspectable manual pattern is:

```bash
curl -fL --retry 3 -o /tmp/starship-install.sh https://starship.rs/install.sh
sha256sum /tmp/starship-install.sh
less /tmp/starship-install.sh
sh /tmp/starship-install.sh -b "$HOME/.local/bin" -y
```

Use the equivalent exact source shown above for other tools. Do not collapse this
sequence into `curl | sh`.

## Installed targets

```text
~/.bashrc
~/.bash_aliases
~/.inputrc
~/.config/starship.toml
~/.config/terminator/config
```

The Codex example is not copied automatically. `cxl` does not need it. Review
and opt in manually if a standalone profile is useful:

```bash
install -Dm600 config/codex/local-qwen.config.toml.example \
  "${CODEX_HOME:-$HOME/.codex}/local-qwen.config.toml"
```

Never place auth tokens, personal MCP servers, hooks, or session state in that
example or in this repository.

## Manual configuration-only install

First create your own backup:

```bash
stamp=$(date +%Y%m%d-%H%M%S)
mkdir -p "$HOME/.local/state/sobatista-terminal/manual-$stamp"
cp -a ~/.bashrc ~/.bash_aliases ~/.inputrc \
  "$HOME/.local/state/sobatista-terminal/manual-$stamp/" 2>/dev/null || true
```

Then install reviewed files:

```bash
install -Dm600 config/bash/bashrc ~/.bashrc
install -Dm600 config/bash/bash_aliases ~/.bash_aliases
install -Dm600 config/bash/inputrc ~/.inputrc
install -Dm600 config/starship/starship.toml ~/.config/starship.toml
install -Dm600 config/terminator/config ~/.config/terminator/config
```

Manual installs do not create the project manifest; automatic uninstall cannot
safely identify them. Restore them using the backup you created.

## Rollback and uninstall

The installer prints a command containing the exact backup path. You can also
list timestamps:

```bash
bash uninstall.sh --list-backups
bash uninstall.sh --dry-run --restore 20260823-120000
bash uninstall.sh --restore 20260823-120000
```

Only a backup under the project's XDG backup root with valid metadata is accepted.
Current files are preserved before restoration. Without `--restore`, files are
removed only when their SHA-256 still matches the install manifest. Modified
files remain in place. Backup directories remain after uninstall.

## After installation

Open a new Bash process and fully restart Terminator:

```bash
exec bash
llm_check
termhelp
terminator -l AI-Workbench
```

The Terminator configuration ships two profiles: the subtly transparent
`default` (near-black `#070B0D` at 94 % opacity) and a fully opaque
`BlackIce-Solid`. Use the solid profile for screenshots, screen sharing, and
sensitive contexts: `terminator --no-dbus --profile=BlackIce-Solid`. Terminal
transparency is a Terminator profile setting and is independent of the shell's
`SOBATISTA_SCREENSHOT_MODE`, which only changes the displayed prompt identity.

If Ollama was installed but its API was stopped, the installer does not start a
hidden background process. Start the service explicitly, verify with
`llm_check`, then pull the intended model.
