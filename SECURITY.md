# Security policy

## Supported versions

Until `1.0.0`, security fixes are provided for the latest tagged `0.x` release
only. Users should review changes and update to the latest release. The `main`
branch is development state, not a supported release.

## Report privately

Use GitHub's **Report a vulnerability** private reporting feature for this
repository. Include:

- Affected version/commit and distribution.
- Reproduction steps using non-sensitive test data.
- Impact, prerequisites, and whether user interaction is required.
- A proposed fix or mitigation if available.

Do not open a public issue for an unpatched vulnerability. Do not include live
tokens, personal configuration, client information, engagement output, target
addresses, recovery codes, or copies of `~/.codex` state. Redact minimally and
describe how maintainers can reproduce with safe fixtures.

If private reporting is temporarily unavailable, open a public issue containing
only the statement that the private reporting channel is unavailable. Do not
include vulnerability details. A maintainer will arrange a private channel.

## Response targets

Maintainers aim to acknowledge a complete report within five business days and
provide a status update within ten business days. These are best-effort targets,
not a service-level agreement.

## Scope

Security-sensitive areas include:

- Installer/uninstaller path validation, backup integrity, and privilege use.
- Shell injection, unsafe quoting, or command execution from untrusted input.
- Exposure of credentials, Codex state, private paths, or security-testing data.
- Release workflow tag integrity and permission boundaries.
- Local/cloud AI boundary confusion that could send intended-local content to a
  cloud provider.

The following are generally not vulnerabilities by themselves:

- A documented command doing what the user explicitly asked it to do.
- Ollama/Codex/model behavior or upstream vulnerabilities outside this project's
  wrapper/configuration code.
- Security helpers used without authorization.
- Unsupported distributions or modified configurations outside the documented
  support boundary.

## Safe research

Test only systems and accounts you own or are authorized to use. Prefer temporary
homes, containers, mocked package managers, and synthetic data. Do not access,
retain, or disclose other people's data. Avoid availability impact and stop when
a test crosses the repository's code into an unrelated service.

The project will not pursue action against good-faith research that follows this
policy, avoids privacy/availability harm, and gives maintainers reasonable time
to remediate before disclosure.
