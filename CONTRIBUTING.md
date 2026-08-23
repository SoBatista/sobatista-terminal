# Contributing

Thank you for improving SoBatista Terminal. Contributions are welcome when they
preserve safe installation, explicit trust boundaries, and honest distribution
support.

By participating, you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).

## Before opening a change

1. Search existing issues and pull requests.
2. Open an issue before a broad behavioral, visual, installer, or release-design
   change. Small fixes can go directly to a focused PR.
3. Never attach or commit shell history, credentials, private hostnames, target
   addresses, client data, Codex auth/session state, Ollama model data, or live
   security-testing output.
4. Use security helpers only in authorized environments.

Security vulnerabilities belong in a private report under [SECURITY.md](SECURITY.md),
not a public issue.

## Development setup

Fork and branch from current `main`:

```bash
git switch main
git pull --ff-only
git switch -c fix/short-description
bash install.sh --self-test
```

For the full suite, install Bats, ShellCheck, shfmt, and Python 3.11 or newer,
then run:

```bash
scripts/self-test.sh
git diff --check
```

Use a temporary `HOME` for installer experiments. Never point experimental
installer code at a real home directory before dry-run, Bats, and manual review.

## Change requirements

- Keep Bash quoted and ShellCheck-clean.
- Preserve clean behavior when optional tools are absent.
- Add Bats coverage for behavior changes and installer edge cases.
- Document every added or changed public alias/function in `docs/commands.md`
  and the relevant `termhelp` topic.
- Keep Starship optional modules separator-complete.
- Do not add support claims without a repeatable test or an explicit limitation.
- Pin GitHub Actions to immutable 40-character commit SHAs.
- Do not weaken backup, manifest, root refusal, or dry-run behavior.

## Release impact: exactly one bump

Every PR, including documentation and dependency maintenance, must carry exactly
one label and matching version change:

- `release:major` for a breaking change.
- `release:minor` for a backward-compatible feature.
- `release:patch` for fixes, docs, configuration, tests, or maintenance.

Update `VERSION`, the README version badge/declaration, and add a dated
`CHANGELOG.md` section for the new version. CI compares the PR with its base and
rejects a missing, multiple, or mismatched release label.

Do not edit or recreate an existing tag. See [maintenance](docs/maintenance.md)
for the protected-branch and automated-release design.

## Commit and PR quality

Prefer small, reviewable commits with imperative subjects, for example:

```text
feat: add persistent Ollama model selector
test: cover temporary-home rollback
docs: clarify Fedora reboot checks
```

The PR description must include intent, migration or rollback impact, test
evidence, distribution impact, screenshot status, and release impact. Screenshots
must follow [the real-capture workflow](docs/screenshots.md).

Maintainers may request a replacement capture, additional distribution evidence,
or a narrower change. No contributor or automation should merge to `main` without
the maintainer's explicit approval and required checks.
