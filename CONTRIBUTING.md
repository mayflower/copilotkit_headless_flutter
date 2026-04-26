# Contributing

Thanks for helping improve `copilotkit_headless_flutter`.

## Development Setup

Use the Flutter stable channel and the Dart SDK required by `pubspec.yaml`.

```sh
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
dart doc --dry-run .
```

The example app has its own package context:

```sh
cd example
flutter pub get
flutter analyze
flutter test
```

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
