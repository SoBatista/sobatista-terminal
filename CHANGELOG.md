# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-08-23

### Added

- Separate stable-release and contributor installation paths in the README and
  installation guide, including what installing from a moving development branch
  costs and what `--dev-link` changes for every newly opened shell.
- `tests/release-install.bats`: installation from a release-shaped source tree
  (tracked files only, no `.git`) into a temporary `HOME`, covering the five
  documented targets and their modes, Starship and Terminator parsing, a clean
  interactive Bash shell that resolves the public commands, uninstall, and
  rollback. `SOBATISTA_RELEASE_REF` points the same suite at a published tag.
- A manual `Release verification` workflow (`workflow_dispatch`) that installs
  from the published release tarball of an existing tag and proves the tarball
  matches that tag, covering what a pull request cannot check before its own tag
  exists.
- A documented changelog link policy, the exact required status-check names, and
  a post-release verification procedure in the maintenance guide.

### Fixed

- Removed the obsolete pre-release link-check exclusion for the changelog
  `Unreleased` compare link, which `v0.1.0` turned into a valid, checked link,
  and replaced the broad release-tag exclusion with an exact SemVer-anchored
  rule that documents the release-page lifecycle instead of adding one
  exception per version.
- Made the public-command documentation check deterministic. Its membership test
  piped the whole token list into `grep -Fxq`; `grep -q` exits at its first
  match, and when it closed the pipe before the forked `printf` flushed, the
  resulting `SIGPIPE` became a pipeline failure under `set -o pipefail` and a
  documented command was reported as undocumented. Membership now resolves
  through an associative array, so `scripts/self-test.sh` and the CI quality job
  no longer fail intermittently on early-sorting names such as `burp_off`.
- Configured `MD024` with `siblings_only` so Markdown linting accepts the
  repeated `### Added` / `### Fixed` headings that Keep a Changelog requires. The
  default setting would have failed the first release after `0.1.0` regardless
  of its content; duplicate headings inside a single version section are still
  reported.
- Documented the missing copy step for the opt-in Terminator separator
  stylesheet. The customization guide imported `~/.config/terminator/gtk.css`,
  which the installer does not create, and GTK ignores an `@import` whose target
  is missing, so following the guide silently did nothing.
- Listed the shipped `dev` topic in the `termhelp` topic lists in the README and
  the command reference.
- Replaced the maintenance guide's pre-release GitHub-settings advice with the
  actual `main` protection design, the check names GitHub really reports, and a
  solo-maintainer review policy that does not depend on the owner approving
  their own pull request.
- Corrected the container-pinning note: the link-checker image is already pinned
  to an immutable digest.

## [0.1.0] - 2026-08-23

### Added

- Production-ready Bash, Readline, Starship, and Terminator configuration.
- Direct Ollama/Qwen workflows and separate cloud/local Codex helpers.
- Idempotent, cross-distribution installation, backup, rollback, and removal.
- Discoverable terminal help covering commands, keys, AI, Git, updates,
  authorized security testing, the privacy terminal, and developer link mode.
- Subtly transparent Black Ice default profile (0.90) with a solid
  `BlackIce-Solid` profile and a `privacy` command for screen-sharing-safe
  windows.
- Developer `--dev-link` install mode that live-links the shell/Readline files
  to the repository, with `termreload` and `termdev_status` helpers and
  symlink-aware backup, uninstall, and restore.
- Automated syntax, behavior, portability, documentation, security, and release
  validation.
- Open-source governance, maintenance, contribution, and security policies.

[Unreleased]: https://github.com/SoBatista/sobatista-terminal/compare/v0.1.0...HEAD
[0.1.1]: https://github.com/SoBatista/sobatista-terminal/releases/tag/v0.1.1
[0.1.0]: https://github.com/SoBatista/sobatista-terminal/releases/tag/v0.1.0
