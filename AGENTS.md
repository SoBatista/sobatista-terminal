# Repository instructions

These instructions apply to the entire repository.

## Project boundaries

- Support Bash on Debian/Ubuntu/Mint, Fedora, and Arch Linux only. Do not claim
  broader testing or compatibility.
- Keep shell configuration portable across the supported families. Optional
  commands must degrade cleanly when their dependency is absent.
- Never add credentials, tokens, private hostnames, target addresses, shell
  history, Codex auth/session state, Ollama model data, or security-engagement
  output.
- Do not read or copy a contributor's `~/.codex/auth.json`, private MCP config,
  rollout database, hooks, or provider credentials.
- Security helpers must remain explicit, auditable, and labeled for authorized
  use. Do not add aliases that disguise destructive or intrusive behavior.
- Do not add cache-dropping commands. Linux filesystem cache is beneficial and
  automatically reclaimed.

## Engineering rules

- Use Bash for user-facing shell and installer code. Quote expansions, use `--`
  before path operands, and preserve meaningful exit statuses.
- Installer changes must remain idempotent, refuse root, support dry runs, back
  up changed files, and never delete unknown user data.
- Treat files outside this repository as untrusted and potentially sensitive.
- Keep public aliases and functions documented in `docs/commands.md` and in the
  relevant `termhelp` topic.
- Keep `VERSION`, `CHANGELOG.md`, release notes, and release metadata consistent.
- Pin every GitHub Action to a full commit SHA. Dependabot is responsible for
  proposing reviewed updates.
- Do not add fabricated screenshots. Only accept captures from the configured
  Terminator environment after a sensitivity review.

## Review checklist

Reviewers must check:

1. Correct quoting and behavior with spaces, pipes, empty input, and missing
   optional dependencies.
2. Cross-distribution package names and honest support claims.
3. Backup/restore safety, manifest validation, and dry-run accuracy.
4. Prompt modules for contrast and orphaned separators.
5. AI command separation: `q*` is direct Ollama, `cx*` cloud Codex, and `cxl*`
   local Ollama-backed Codex.
6. Secret, personal-path, and machine-specific data exposure.
7. Tests and documentation for every public behavior change.

Run `scripts/self-test.sh` before approving. Never merge to `main` on behalf of
the maintainer without explicit approval.
