# Security Policy

## Supported Versions

Security fixes are provided for the latest released minor version. Before
`1.0.0`, consumers should expect to update to the newest `0.x` release to pick
up security fixes.

## Reporting a Vulnerability

Please do not open public issues for security vulnerabilities.

Use GitHub private vulnerability reporting or create a private security advisory
for this repository:

- [Report a vulnerability privately](https://github.com/mayflower/copilotkit_headless_flutter/security/advisories/new)
- [View this repository's security policy](https://github.com/mayflower/copilotkit_headless_flutter/security/policy)

Include:

- Affected version or commit.
- Minimal reproduction or exploit sketch.
- Impact and affected APIs.
- Any known mitigations.

Maintainers will acknowledge valid reports as soon as practical, coordinate a
fix privately, and publish a security advisory when the fix is available.

## Security Scope

This package is a headless client library. The main security-sensitive surfaces
are:

- Tool registration and permission checks.
- Tool result payloads and error payloads.
- AG-UI event decoding and reducer behavior.
- HTTP/SSE transport configuration.
- Shared state patching.

Do not put secrets in AG-UI messages, tool arguments, shared state, debug logs,
or renderer payloads unless the consuming application has explicit redaction and
storage controls.
