# Troubleshooting

## Shell configuration does not load

Confirm Bash is the interactive shell and run syntax checks without sourcing:

```bash
printf 'shell=%s bash=%s\n' "$SHELL" "$BASH_VERSION"
bash -n ~/.bashrc ~/.bash_aliases
bash --noprofile --norc
```

If the clean shell works, inspect the exact backup printed by the installer and
use `bash uninstall.sh --dry-run --restore TIMESTAMP` before restoring it.

## Prompt is plain or glyphs are boxes

```bash
command -v starship
fc-match 'JetBrainsMono Nerd Font Mono'
python3 -c 'import pathlib, tomllib; tomllib.load((pathlib.Path.home() / ".config/starship.toml").open("rb"))'
```

Fully restart Terminator after font/profile changes. Verify Terminator selected
`JetBrainsMono Nerd Font Mono`, not the proportional family or a similarly named
non-Nerd font.

## Empty or doubled Starship separators

Compare the installed file to `config/starship/starship.toml`. Optional modules
must retain both their `[]` and `[]` glyphs inside the module's own `format`.
Do not move an optional module's separator into the global format.

## `qm` cannot select a model

```bash
command -v ollama
ollama list
command -v fzf
qmodels
```

Without `fzf`, use `qmodel EXACT_MODEL_NAME`. Only installed model names are
accepted. The selection state must be a regular readable file containing one
validated model name.

## Ollama is installed but unavailable

```bash
llm_check
systemctl status ollama --no-pager
curl -fsS --max-time 3 http://127.0.0.1:11434/api/tags
```

Start the service according to the official Ollama installation mode. The
project does not silently start an unmanaged background server. If a selected
model is missing, pull it explicitly and repeat `llm_check`.

## Direct `q` pipes behave unexpectedly

`q 'instruction'` joins its arguments into one prompt. With piped stdin, it adds
an `Instruction` and `Input` boundary. Without an instruction, stdin is passed
directly to `ollama run`. Confirm aliases from other dotfiles have not replaced
the function:

```bash
type -a q
declare -f q
```

## Cloud versus local Codex

```bash
cxd
cmdhelp cx
cmdhelp cxl
llm_check
```

`cx` uses normal Codex auth/config. `cxl` passes `--oss --local-provider ollama`
and the model selected by `qm`. The project never copies Codex authentication.
If the installed Codex version does not recognize these flags, update it through
the inspectable `updatecodex` flow and consult the official CLI reference.

## Update helper does not cover an application

This is often expected. `termhelp updates` lists boundaries. AppImages, arbitrary
source checkouts, all language toolchains, browser extensions, and manual installs
need their own trusted update path.

Do not add a cache-dropping workaround. Linux filesystem cache improves
performance and is automatically reclaimed under memory pressure.

## Installer rejects the distribution

Inspect `/etc/os-release`. Only Debian/Ubuntu/Mint, Fedora, and Arch family IDs
are accepted. `--configs-only` is available when you accept that package and GUI
behavior is outside the tested support boundary. Do not spoof distribution IDs
for a full software install.

## Rollback refuses a path

`--restore` accepts only a metadata-bearing backup inside the project's XDG state
backup root. Use `bash uninstall.sh --list-backups` and pass the printed timestamp
or absolute path. This prevents an arbitrary directory from becoming an overwrite
source.
