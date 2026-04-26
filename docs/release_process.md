# Release Process

## Checks

Run these before tagging:

```sh
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
dart doc --dry-run .

cd example
flutter pub get
flutter analyze
flutter test
```

## Versioning

Use semantic versioning.

- Patch: compatible bug fixes.
- Minor: compatible features or API additions.
- Major: breaking changes.

Before `1.0.0`, breaking changes may happen in minor releases, but they must be
called out clearly in `CHANGELOG.md`.

## Tags

Use `v{{version}}` tags, for example:

```sh
git tag v0.1.0
git push origin v0.1.0
```

Apps can consume tagged Git versions with Dart's `tag_pattern` support:

```yaml
dependencies:
  copilotkit_headless_flutter:
    git:
      url: git@github.com:mayflower/copilotkit_headless_flutter.git
      tag_pattern: v{{version}}
    version: ^0.1.0
```
