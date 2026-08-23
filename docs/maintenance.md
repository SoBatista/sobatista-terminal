# Maintenance and releases

## Local quality gate

Install the developer tools through the supported distribution, then run:

```bash
scripts/self-test.sh
```

The full local gate requires Bash, Python 3.11+ (`tomllib`), Bats, ShellCheck,
and shfmt. It performs:

1. Bash syntax validation for every shell source.
2. Repository secret and machine-specific value checks.
3. Version/changelog/README consistency validation.
4. Starship and Codex example TOML parsing.
5. Terminator profile/layout presence checks.
6. ShellCheck and canonical `shfmt -d` formatting.
7. Bats behavior, installer, model, rollback, and update tests.

CI additionally runs Markdownlint, online/local link checking, Actionlint,
Gitleaks, and read-only Ubuntu/Fedora/Arch container smoke tests.

## Supported-versus-tested boundary

The package-manager adapter and configuration are maintained for:

- Debian, Ubuntu, and Linux Mint via APT.
- Fedora via DNF5 or DNF.
- Arch Linux via pacman.

Ubuntu, Fedora, and Arch container jobs test non-root configuration installation
and clean Bash loading. Containers do not test desktop font selection,
Terminator rendering, systemd service activation, GPU drivers, or multi-gigabyte
Ollama pulls. Those limitations must remain explicit in release notes.

## One pull request, one version

Every PR merged into `main` must include exactly one version increase:

- `release:major`: breaking behavior; `X.y.z` becomes `X+1.0.0`.
- `release:minor`: backward-compatible feature; `x.Y.z` becomes `x.Y+1.0`.
- `release:patch`: fix, documentation, configuration, or maintenance;
  `x.y.Z` becomes `x.y.Z+1`.

The PR must update the root `VERSION`, add a dated section for that version in
`CHANGELOG.md`, update the README version declaration/badge, and carry exactly
one matching label. `scripts/check-version.sh --pr BASE_REF` enforces the bump.

Requiring the reviewed PR to carry the version avoids a post-merge bot commit.
That preserves branch protection, eliminates bot workflow loops, and makes the
exact release state visible during review. It also means documentation-only and
dependency-update PRs need a patch bump before merge.

## Automated release flow

1. The PR workflow validates the impact label, exact bump, changelog, and all
   quality gates.
2. Branch protection permits merge only after required checks and review.
3. The merge brings the already-reviewed canonical version to `main`.
4. CI runs on the resulting `main` commit.
5. Only a successful CI `workflow_run` triggers the release workflow.
6. `scripts/release.sh --publish` checks the version and existing tags, creates
   annotated `vX.Y.Z`, and creates a GitHub Release from that version's reviewed
   changelog section.

The workflow uses a single `release-main` concurrency group with cancellation
disabled. A rerun is idempotent: an existing tag must point to the same commit,
and an existing GitHub Release is reused. A tag pointing elsewhere causes a hard
failure and is never moved or rewritten.

## Required GitHub settings

Configure the repository before the first release:

- Protect `main`; require a pull request and at least one approving review.
- Require the `CI / quality` and `CI / release metadata` checks.
- Require branches to be up to date before merge.
- Block force pushes and branch deletion.
- Restrict direct pushes to `main` (prefer no bypass actors).
- Give the release workflow `contents: write`; leave other workflows read-only.
- Enable GitHub private vulnerability reporting and secret scanning where the
  repository plan supports them.
- Keep “Allow GitHub Actions to create and approve pull requests” disabled; this
  design does not need it.

If policy forbids tag creation by `GITHUB_TOKEN`, use a protected release
environment with an approved GitHub App token. Do not weaken `main` protection or
grant broad write permission to CI.

## Pinned actions and Dependabot

Every `uses:` entry is pinned to a 40-character commit SHA. A trailing comment
records the human-readable release. Dependabot opens weekly updates for GitHub
Actions. Treat a SHA update like a dependency change: inspect upstream release
notes and diff, let CI run, apply a patch bump, and merge only after review.

Container image tags used for lint and smoke tools are explicit versions. Review
their upstream digests during maintenance; a future hardening step may pin image
digests where multi-architecture publishing is stable.

## Manual release verification

Before approving a release-impact PR:

```bash
scripts/check-version.sh --consistency
scripts/release.sh --check
git diff --check
scripts/self-test.sh
```

After automation completes, verify that `vX.Y.Z` targets the merged commit, the
release notes match the reviewed changelog, and no tag was replaced.
