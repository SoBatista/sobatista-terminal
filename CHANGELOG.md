# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.3] - 2026-08-24

### Changed

- `actions/checkout` in the release-verification workflow moves from `v6.0.2` to
  `v7.0.1`, pinned to digest `3d3c42e5aac5ba805825da76410c181273ba90b1`. It was
  the last call site still on `v6.0.2`, so every workflow now checks out with
  the same reviewed digest.

## [0.1.2] - 2026-08-24

### Fixed

- Kept the link check honest when a third-party host stops answering. Two pushes
  to `main` two minutes apart checked the same 35 links: the first finished in
  679 ms, the second timed out after 50 s on both `contributor-covenant.org`
  links and failed the `quality` job, while both URLs answer 200 from a
  workstation. Retry waits of one and two seconds put every attempt inside the
  same window of unavailability. The retry budget now spreads four attempts over
  at least 70 seconds of waiting rather than three attempts over three seconds,
  so a short outage expires between them. The per-request timeout is unchanged
  on purpose: a connection that is never accepted is abandoned after ten seconds
  whatever that timeout says. Excluding the URLs, accepting timeouts, or
  dropping external link checking would each have kept the links in the file
  while no longer checking them. A genuinely broken link still fails the build,
  and now takes about two minutes to say so.
- Pointed the Code of Conduct attribution at the Contributor Covenant address
  the site actually serves, removing a `301` hop and halving the requests this
  repository makes to the host that timed out.
- Stopped CI cancelling itself into a permanent failure. Opening a pull request
  with its `release:*` label already applied fires `opened` and `labeled` in the
  same second; both landed in one CI concurrency group, `cancel-in-progress`
  killed the first, and the cancelled `quality` check run stayed on the head
  commit as a non-success that nothing re-evaluates. The pull request then read
  as failing with every job that finished green. Label events now belong to a
  separate `Release metadata` workflow, which does not cancel and reads the
  labels from the API instead of the event payload, so its concurrent runs
  cannot reach different verdicts. CI keeps the default pull-request events, so
  one push produces exactly one run of `quality` and the smoke jobs.

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
- Re-run pull-request validation when a release label changes. CI read
  `github.event.pull_request.labels`, a snapshot taken when the event fired, but
  did not subscribe to `labeled`/`unlabeled`. Following the documented flow —
  open the pull request, then apply exactly one `release:*` label — therefore
  left `release metadata` failing on a stale empty label list, clearable only by
  a manual rerun or an unrelated push.
- Configured `MD024` with `siblings_only` so Markdown linting accepts the
  repeated `### Added` / `### Fixed` headings that Keep a Changelog requires. The
  default setting would have failed the first release after `0.1.0` regardless
  of its content; duplicate headings inside a single version section are still
  reported.
- Made the screenshot guide's capture instructions self-consistent. Its shared
  settings require the opaque `BlackIce-Solid` profile because a transparent
  background leaks whatever is behind the window, but every numbered capture then
  said to use the transparent `default` profile. The numbered captures now match
  the rule, and the `AI-Workbench` capture states the real constraint: that layout
  pins `profile = default` on each of its terminals and `-p` cannot override it,
  so that one capture is transparent and the desktop behind it must be cleared.
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

[Unreleased]: https://github.com/SoBatista/sobatista-terminal/compare/v0.1.1...HEAD
[0.1.2]: https://github.com/SoBatista/sobatista-terminal/releases/tag/v0.1.2
[0.1.1]: https://github.com/SoBatista/sobatista-terminal/releases/tag/v0.1.1
[0.1.0]: https://github.com/SoBatista/sobatista-terminal/releases/tag/v0.1.0
