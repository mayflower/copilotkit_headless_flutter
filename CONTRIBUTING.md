# Contributing

Thanks for helping improve `copilotkit_headless_flutter`.

## Development Setup

Use the Flutter stable channel and the Dart SDK required by `pubspec.yaml`.

```sh
flutter pub get
make package-check
```

The example app has its own package context:

```sh
make example-check
```

## Local Quality Tools

Install these tools if you want to run the full local quality suite:

- `actionlint` for GitHub Actions workflow linting.
- `zizmor` for GitHub Actions security analysis.
- `gitleaks` for local secret scanning.
- Node.js with `npx` for `markdownlint-cli2`.

Useful targets:

```sh
make quality
make coverage
make pana
make pub-outdated
make tooling-check
```

`make quality` runs package checks, example checks, Markdown linting, workflow
linting, workflow security analysis, and secret scanning. `make pana` runs a
pub.dev-style package quality analysis on a temporary copy of the repository.

## Project Boundaries

This package should stay headless and app-agnostic. Keep platform auth,
application storage, Riverpod providers, product-specific tools, and backend
configuration in consuming apps.

Good package candidates:

- AG-UI protocol models, reducers, sessions, and portable transports.
- CopilotKit-style actions, tool runloop, renderer registries, and CoAgent
  shared state.
- Generic HTTP/SSE transport code with injectable headers and URLs.

Poor package candidates:

- App database schemas.
- Product-specific API clients.
- Built-in mobile tools that need permissions, platform channels, or app UX.
- Application state-management adapters.

## Pull Requests

- Keep public API changes deliberate and documented.
- Add or update tests for behavior changes.
- Update `CHANGELOG.md` for user-visible changes.
- Prefer small, reviewable pull requests over broad refactors.
- Do not import from `lib/src` in downstream examples or apps.

## API Stability

Before `1.0.0`, minor versions may refine public APIs. Breaking changes must be
called out in `CHANGELOG.md` with migration notes. After `1.0.0`, breaking
changes require a major version bump.

## Commit Style

Use concise, conventional-style subjects where practical:

- `feat: add state renderer registry`
- `fix: preserve tool call arguments during follow-up`
- `docs: explain headless chat setup`
- `test: cover remote-only tool calls`
