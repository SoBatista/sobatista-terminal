# Roadmap

The roadmap is directional, not a promise of dates. Changes still require an
issue, review, tests, one SemVer bump, and a changelog entry.

## 0.1.x hardening

- Complete real, sanitized screenshot capture and visual regression review.
- Expand clean-container coverage across stable Debian and Linux Mint where
  maintainable images and desktop-independent checks are available.
- Add tested package-name probes for distribution release changes.
- Evaluate digest pinning for CI container images without breaking supported
  runner architectures.

## 0.2.0 candidates

- Opt-in modular local override hooks with explicit trust documentation.
- More Bats coverage for interrupted Ollama streams and Codex resume failures.
- An offline configuration bundle verifier with published checksums.
- Accessibility review for common color-vision deficiencies and low-brightness
  displays.

## Later exploration

- Additional terminal emulators only when maintainers can test them honestly.
- Signed release provenance and artifact attestations.
- A package-manager-neutral font discovery helper.

## Out of scope

- Universal Linux compatibility claims.
- Automatic handling of credentials or Codex authentication.
- Hidden destructive Git commands, cache-dropping aliases, or opaque security
  automation.
- Live engagement output, target profiles, client data, or pentest evidence.
