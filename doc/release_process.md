# Release Process

## Checks

Run these before tagging:

```sh
flutter pub get
make package-check
make example-check
make quality
make pana
make pub-outdated
dart pub publish --dry-run
```

## Versioning

Use semantic versioning.

- Patch: compatible bug fixes.
- Minor: compatible features or API additions.
- Major: breaking changes.

Before `1.0.0`, breaking changes may happen in minor releases, but they must be
called out clearly in `CHANGELOG.md`.

## Tags

Use signed `v{{version}}` tags when possible. For example:

```sh
git tag -s v0.1.0 -m "v0.1.0"
git push origin v0.1.0
```

If local GPG signing is not available, use an annotated tag and set up signing
before the next release:

```sh
git tag -a v0.1.0 -m "v0.1.0"
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

## pub.dev

The release workflow publishes tags that match `v{{version}}` through pub.dev
automated publishing. A maintainer must publish the first package version
manually and enable GitHub Actions automated publishing for:

- Repository: `mayflower/copilotkit_headless_flutter`
- Tag pattern: `v{{version}}`
- Environment: `pub.dev`

## GitHub Release Artifacts

Pushing a release tag also creates a GitHub Release with:

- Source archive: `copilotkit_headless_flutter-v{{version}}.tar.gz`
- SPDX SBOM: `sbom.spdx`
- Checksums: `SHA256SUMS`
- GitHub artifact attestations for all attached assets

The pub.dev package remains the canonical install artifact. GitHub release
assets are for review, provenance, and enterprise intake.
