# Command reference

This document covers every public alias and function installed by SoBatista
Terminal. Names beginning with `_sb_` are implementation details and are not a
stable public interface. Run `cmdhelp NAME` to see Bash's live resolution.

## Navigation and files

| Command | Type | Behavior |
| --- | --- | --- |
| `..` | Alias | Change to the parent directory. |
| `...` | Alias | Change two directories up. |
| `....` | Alias | Change three directories up. |
| `-` | Alias | Return to the previous directory with `cd -`. |
| `ll` | Alias | Long, human-readable, all-file listing; uses `eza` when installed. |
| `lt` | Alias | Same listing ordered by modification time. |
| `lsize` | Alias | Same listing ordered by size. |
| `pathlines` | Alias | Print one `PATH` entry per line. |
| `dirsize` | Alias | Show one-filesystem sizes for children of the current directory. |
| `diskfree` | Alias | Show filesystem types and human-readable free space. |
| `meminfo` | Alias | Show human-readable memory and swap use. |
| `mkcd DIRECTORY` | Function | Create a directory, including parents, and enter it. |
| `croot` | Function | Change to the current Git worktree root. |
| `backup PATH` | Function | Copy a file or directory to `PATH.bak.TIMESTAMP`. |

When GNU `dircolors` exists, `ls` and `grep` are conditionally aliased to their
`--color=auto` forms.

## Git

| Command | Expansion | Notes |
| --- | --- | --- |
| `g` | `git` | General shorthand. |
| `gst` | `git status --short --branch` | Compact status. |
| `ga` | `git add` | Add named paths. |
| `gap` | `git add --patch` | Interactively stage hunks. |
| `gaa` | `git add --all` | Stage all worktree changes. |
| `gc` | `git commit` | Open the normal commit flow. |
| `gcm` | `git commit -m` | Commit with an explicit message argument. |
| `gca` | `git commit --amend` | Explicitly amend the last commit. |
| `gd` | `git diff` | Show unstaged changes. |
| `gds` | `git diff --staged` | Show staged changes. |
| `gl` | `git log --graph --decorate --oneline --all` | Compact graph. |
| `gb` | `git branch` | Local branches. |
| `gba` | `git branch --all` | Local and remote branches. |
| `gsw` | `git switch` | Switch branches. |
| `gsc` | `git switch -c` | Create and switch to a branch. |
| `gr` | `git restore` | Explicit worktree restore command. |
| `grs` | `git restore --staged` | Unstage named paths. |
| `gf` | `git fetch --all --prune` | Refresh and prune remote refs. |
| `gp` | `git push` | Normal push. |
| `gpf` | `git push --force-with-lease` | Lease-protected force push; never plain `--force`. |
| `gup` | `git pull --ff-only` | Refuse non-fast-forward pulls. |
| `gw` | `git worktree` | Worktree command namespace. |
| `gwl` | `git worktree list` | List worktrees. |
| `gwa` | `git worktree add` | Add a worktree with explicit arguments. |

There is deliberately no alias for `reset --hard`, branch deletion, worktree
removal, clean, or unconditional force-push.

## Development and Docker

| Command | Type | Behavior |
| --- | --- | --- |
| `py` | Alias | Run `python3`. |
| `json` | Alias | Pretty-print JSON with `jq`. |
| `watch1` | Alias | Run `watch` every second with differences highlighted. |
| `venv` | Function | Create `.venv` if needed, then activate it. |
| `serve [PORT]` | Function | Serve the current directory on loopback only; default port 8000. |
| `serve_lan [PORT]` | Function | Explicitly bind the server to all interfaces and print a warning. |
| `urlencode TEXT` | Function | URI-encode text with `jq`. |
| `d` | Alias | Run `docker`. |
| `dc` | Alias | Run `docker compose`. |
| `dps` | Alias | List Docker containers. |
| `dcu` | Alias | Run `docker compose up`. |
| `dcud` | Alias | Run `docker compose up -d`. |
| `dcd` | Alias | Run `docker compose down`. |
| `dcl` | Alias | Follow the last 200 Compose log lines. |
| `dex` | Alias | Start an interactive `docker exec`; pass container and command. |

## Administration and updates

| Command | Type | Behavior |
| --- | --- | --- |
| `ports` | Alias | Show listening TCP/UDP sockets and owning processes where permitted. |
| `routes` | Alias | Show the IP route table. |
| `interfaces` | Alias | Show brief interface/address state. |
| `failed` | Alias | Show failed systemd units. |
| `services` | Alias | Show running systemd services. |
| `jboot` | Alias | Show warning-or-higher journal entries from this boot. |
| `jfollow` | Alias | Follow the system journal. |
| `topcpu` | Alias | Show the 20 highest-CPU process rows. |
| `topmem` | Alias | Show the 20 highest-memory process rows. |
| `pkg_search QUERY` | Function | Search with APT, DNF/DNF5, or pacman. |
| `pkg_install PACKAGE...` | Function | Install explicit packages through the detected manager and `sudo`. |
| `system_update` | Function | Update APT, DNF/DNF5, or pacman packages. |
| `apps_update` | Function | Update installed Flatpak, Snap, pipx, and tldr ecosystems. |
| `restartcheck` | Function | Evaluate available Debian/Ubuntu or Fedora reboot hints. |
| `updateall` | Function | Run system and app updates, explain exclusions, then check restart state. |
| `updateollama` | Function | Download, identify, offer for inspection, then optionally run the official installer. |
| `updatecodex` | Function | Same guarded update flow for the official Codex installer. |
| `updatestarship` | Function | Same guarded update flow for Starship, targeting `~/.local/bin`. |
| `qmodels_update` | Function | Confirm, then pull the latest manifest for every installed Ollama model. |

No update helper covers AppImages, arbitrary source checkouts, every language
toolchain, browser extensions, or all manual installs. The project never drops
Linux filesystem caches.

## Authorized security testing

Use these only for assets you own or are explicitly authorized to assess.

| Command | Type | Behavior |
| --- | --- | --- |
| `headers URL` | Alias | Fetch HTTP response headers with a 15-second limit. |
| `redirects URL` | Alias | Follow and display the HTTP redirect/header chain. |
| `dns NAME` | Alias | Show concise DNS answer records with `dig`. |
| `dns_short NAME` | Alias | Show only short DNS values. |
| `certinfo HOST [PORT]` | Function | Inspect TLS subject, issuer, validity, and SANs; default port 443. |
| `nmap_services TARGET...` | Function | Run default scripts and service/version discovery on open ports. |
| `nmap_all_tcp TARGET...` | Function | Explicit privileged SYN discovery across all TCP ports. |
| `burp_on` | Function | Set HTTP/HTTPS proxy variables to Burp on loopback port 8080. |
| `burp_off` | Function | Clear common HTTP/HTTPS/ALL proxy variables. |
| `burp_status` | Function | Print active proxy variables or a disabled message. |

## Direct Ollama and Qwen

| Command | Behavior |
| --- | --- |
| `llm_check` | Diagnose the Ollama CLI, process/service, loopback API, installed/loaded models, and selected model. |
| `qmodels` | List installed models, selected model, and state-file path. |
| `qmodel [MODEL]` | Fuzzy-select an installed model or persist an explicit one. |
| `qm [MODEL]` | Short function for `qmodel`. |
| `q7` | Persist `qwen2.5-coder:7b`. |
| `q14` | Persist `qwen2.5-coder:14b`. |
| `q30` | Persist `qwen3-coder:30b`. |
| `q [PROMPT]` | Run the selected model directly. No prompt starts interactive Ollama; pipes are preserved. |
| `qrun MODEL [PROMPT]` | One-off model run without changing the selection. |
| `qfile FILE [QUESTION]` | Send a file plus a review question to the selected model. |
| `qdiff [PATH...]` | Review the unstaged diff, or report that it is empty. |
| `qstaged [PATH...]` | Review the staged diff, or report that it is empty. |
| `qcommit` | Ask for one Conventional Commit message from the staged diff. |
| `qlog LOGFILE [LINES]` | Triage the last N lines; default 200. |
| `qcmd COMMAND [ARG...]` | Run an explicit command, display output, and ask the model to explain it. |
| `qps` | Show models currently loaded by Ollama. |
| `qstop [MODEL]` | Unload the named or currently selected model. |
| `qstopall` | Unload every model reported by `ollama ps`. |

`qcmd` executes exactly the argument vector supplied by the user. It is not a
shell-string evaluator, but the command itself can still change the system; read
it before pressing Enter.

## Codex

| Command | Provider | Behavior |
| --- | --- | --- |
| `cx [ARGS...]` | Normal/cloud | Launch Codex with the user's normal config and authentication. |
| `cxask QUESTION` | Normal/cloud | Run an ephemeral, non-interactive Codex task; accepts stdin. |
| `cxr [ARGS...]` | Normal/cloud | Resume the last interactive session for the current directory. |
| `cxer [ARGS...]` | Normal/cloud | Resume the last non-interactive exec session. |
| `cxd [ARGS...]` | Diagnostic | Run `codex doctor`, or explain that Codex is missing. |
| `cxl [ARGS...]` | Local Ollama | Launch Codex with `--oss --local-provider ollama` and the selected model. |
| `cxlask QUESTION` | Local Ollama | Run an ephemeral non-interactive local Codex task; accepts stdin. |
| `cxlr [ARGS...]` | Local Ollama | Resume with the selected local Ollama model. |

Cloud helpers never rewrite Codex auth. Local helpers do not copy or inspect
Codex auth, MCP configuration, sessions, hooks, or rollout databases.

## Help and optional aliases

| Command | Type | Behavior |
| --- | --- | --- |
| `termhelp [TOPIC]` | Function | Open the fuzzy topic menu or print one topic. |
| `th` | Alias | Run `termhelp`. |
| `cmdhelp [COMMAND]` | Function | Fuzzy-select or inspect resolution, aliases, functions, builtins, tldr, man, or `--help`. |
| `ch` | Alias | Run `cmdhelp`. |
| `rgall` | Alias | Search hidden files with ripgrep while excluding `.git`. |
| `hgrep` | Alias | Search shell history with ripgrep. |
| `workbench` | Alias | Open Terminator's `AI-Workbench` layout. |
| `privacy` | Function | Open a new solid `BlackIce-Solid` Terminator window (opaque, for screen sharing) in the current directory; leaves the current terminal untouched and fails clearly if Terminator is absent. |
| `termreload` | Function | Validate `~/.bashrc` and `~/.bash_aliases`, reload `~/.inputrc`, then `exec bash`; a syntax error aborts without replacing the shell. |
| `termdev_status` | Function | Report whether `~/.bashrc`, `~/.bash_aliases`, and `~/.inputrc` are a regular file, a valid symlink (with target), a broken symlink, or missing. |
| `fd` | Conditional alias | Map to Debian/Ubuntu's `fdfind` name when present. |
| `bat` | Conditional alias | Map to Debian/Ubuntu's `batcat` name when present. |
| `sysinfo` | Conditional alias | Run `fastfetch` when present. |
| `cbcopy` | Conditional alias | Copy through Wayland `wl-copy` or X11 `xclip`. |
| `cbpaste` | Conditional alias | Paste through Wayland `wl-paste` or X11 `xclip`. |

`termhelp` topics are `keys`, `ai`, `git`, `shell`, `updates`, `security`,
`privacy`, `dev`, and `discovery` (`discover` is accepted for `discovery`). When
`fzf` is absent, pass the topic or command explicitly.
