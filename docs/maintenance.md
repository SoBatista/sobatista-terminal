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
4. Public alias/function documentation coverage in the README and reference.
5. Starship and Codex example TOML parsing.
6. Terminator profile/layout presence checks.
7. ShellCheck and canonical `shfmt -d` formatting.
8. Bats behavior, installer, model, rollback, update, and release-shape tests.

`tests/release-install.bats` is the release-shape suite: it installs from a
tracked-files-only archive (no `.git`, no ignored working files) into a
temporary `HOME`, checks the five documented targets, loads a clean interactive
Bash shell, and then verifies uninstall and rollback. Point it at an already
published tag with `SOBATISTA_RELEASE_REF=vX.Y.Z bats tests/release-install.bats`.

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
2. Branch protection permits merge only after every required check passes.
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

## Branch protection for `main`

`main` is protected by a repository ruleset that targets `refs/heads/main` and
nothing else. Audit it read-only — never edit it as part of a change:

```bash
gh api repos/SoBatista/sobatista-terminal/rulesets
gh api repos/SoBatista/sobatista-terminal/rules/branches/main
```

The protection this design depends on is:

- Branch deletion blocked and non-fast-forward (force) pushes blocked.
- A pull request required before `main` is updated, with conversation
  resolution required.
- Required status checks, with branches required to be up to date before
  merging.
- Linear history and signed commits on `main`.
- The release workflow holds `contents: write`; every other workflow stays
  read-only.
- GitHub private vulnerability reporting and secret scanning enabled where the
  repository plan supports them.
- “Allow GitHub Actions to create and approve pull requests” left disabled;
  this design does not need it.

If policy forbids tag creation by `GITHUB_TOKEN`, use a protected release
environment with an approved GitHub App token. Do not weaken `main` protection or
grant broad write permission to CI.

### Required status check contexts

Require the checks this repository actually produces. Read the exact names from
GitHub instead of typing them from memory:

```bash
gh api repos/SoBatista/sobatista-terminal/commits/main/check-runs \
  --jq '.check_runs[].name'
gh pr view PR_NUMBER --repo SoBatista/sobatista-terminal \
  --json statusCheckRollup \
  --jq '.statusCheckRollup[] | "\(.workflowName) / \(.name)"'
```

| Workflow | Check name | What it guards |
| --- | --- | --- |
| CI | `quality` | Syntax, ShellCheck, `shfmt -d`, Bats, TOML, Markdown, Actionlint, links |
| CI | `release metadata` | Exactly one release label and one matching SemVer increment |
| CI | `smoke (Ubuntu 24.04)` | Container install and clean interactive shell |
| CI | `smoke (Fedora 44)` | Container install and clean interactive shell |
| CI | `smoke (Arch Linux)` | Container install and clean interactive shell |
| Security | `secrets and sensitive data` | Repository sensitive-data checks and the Gitleaks history scan |

`Release / tag and GitHub Release` must never be a required pull-request check.
It runs only after CI succeeds on `main`, so requiring it would deadlock every
pull request.

A required context that does not match a name GitHub reports never turns green:
the check sits at “Expected” forever and the rule protects nothing while looking
strict. After any change to the required list, confirm on a real pull request
that every required entry resolves to a reported check.

### Reviews during the solo-maintainer phase

GitHub does not let an author approve their own pull request. While this project
has a single maintainer and no other trusted account, a mandatory approving
review makes every pull request unmergeable except through the owner's bypass —
and using the bypass sets aside the rest of the protection for that merge, which
is worse than not requiring the approval at all.

The honest configuration for this phase is therefore: require a pull request,
require the status checks above, require conversation resolution, and require
**zero** mandatory approvals. Raise the approval requirement (and any “extra
approval for unattributed changes” requirement) only once a second trusted
account can actually review the owner's pull requests. Keep the bypass list as
narrow as possible and treat every use of it as a recorded exception, not the
normal merge path.

## Pinned actions and Dependabot

Every `uses:` entry is pinned to a 40-character commit SHA. A trailing comment
records the human-readable release. Dependabot opens weekly updates for GitHub
Actions. Treat a SHA update like a dependency change: inspect upstream release
notes and diff, let CI run, apply a patch bump, and merge only after review.

Container images are pinned as follows: the link checker runs on an immutable
digest (`lycheeverse/lychee:0.24.2@sha256:…`), while the Actionlint, Gitleaks,
and distribution smoke images are pinned to explicit version tags. Review those
tags' upstream digests during maintenance; extending digest pinning to them is
still open, and the distribution smoke images (`ubuntu:24.04`, `fedora:44`,
`archlinux:base`) are deliberately left on their moving tags because the point of
that job is to catch a distribution changing under the installer.

## Changelog link policy

Two kinds of link live at the bottom of `CHANGELOG.md`, and each has a rule that
keeps the link checker honest without per-release exceptions:

- **A version section** (`[0.1.1]`) links to its own GitHub Release page,
  `…/releases/tag/vX.Y.Z`. That page does not exist while the pull request that
  introduces the version is open — the release workflow creates it after the
  merge — so `.lychee.toml` excludes exactly this repository's SemVer
  release-tag pages. One documented rule covers every release; do not add a new
  exclusion per version.
- **`[Unreleased]`** compares the most recently **published** tag to `HEAD`, so
  it is always a valid, checked link. Advance it to `vX.Y.Z` in the first pull
  request *after* `vX.Y.Z` is published — never in the pull request that
  introduces `X.Y.Z`, because that tag does not exist yet and the link would
  need an exception. The consequence is deliberate: during a release pull
  request the compare base is one release behind, and that is preferable to an
  unchecked link.

Never reach for `|| true`, `--accept-all`, a broad `compare/.*` exclusion, a
changelog-wide exclusion, or disabled external link checking. If an exclusion
genuinely cannot be avoided, keep it exact, keep it repository-specific, and
write down why in `.lychee.toml`.

## Manual release verification

Before approving a release-impact PR:

```bash
scripts/check-version.sh --consistency
scripts/check-version.sh --pr origin/main
scripts/release.sh --check
git diff --check
scripts/self-test.sh
```

After automation completes, verify that `vX.Y.Z` targets the merged commit, the
release notes match the reviewed changelog, and no tag was replaced:

```bash
git fetch --prune --tags
git rev-parse main
git rev-parse "vX.Y.Z^{commit}"
gh release view vX.Y.Z --repo SoBatista/sobatista-terminal \
  --json tagName,isDraft,isPrerelease,publishedAt,targetCommitish
gh run list --repo SoBatista/sobatista-terminal --branch main --limit 15
```

### Post-release installation verification

A pull request cannot install from its own tag: `vX.Y.Z` and its GitHub Release
are created only after the merge. CI therefore validates the release *shape*
(`tests/release-install.bats`, installed from a tracked-files-only archive), and
the real published artifact is verified afterwards by the manual
`Release verification` workflow:

```bash
gh workflow run release-verify.yml \
  --repo SoBatista/sobatista-terminal --field tag=vX.Y.Z
gh run list --repo SoBatista/sobatista-terminal --workflow release-verify.yml
```

That job requires a published, non-draft, non-prerelease release, downloads the
tarball GitHub serves for the tag, proves it matches `git archive` of that tag
byte for byte, installs it into a temporary `HOME` as a non-root user, loads a
clean interactive shell, and then uninstalls. It is `workflow_dispatch`-only and
must never become a required pull-request check. Run it once per release, right
after the release workflow finishes.
