# CopilotKit Headless Flutter

Headless CopilotKit-style Flutter APIs over AG-UI. The package provides the
portable agent protocol, reducers, session controller, local frontend tools,
tool runloop, generative UI renderer registries, and CoAgent shared-state APIs.

This package is intentionally transport- and app-agnostic. App-specific auth,
storage, Riverpod providers, mobile-edge clients, and mobile built-in tools stay
in the consuming application as adapters.

## Install

For local development, consume the sibling checkout from the app:

```yaml
dependencies:
  copilotkit_headless_flutter:
    path: ../copilotkit_headless_flutter
```

For release builds, pin a tagged private Git revision:

```yaml
dependencies:
  copilotkit_headless_flutter:
    git:
      url: git@github.com:<org>/copilotkit_headless_flutter.git
      tag_pattern: v{{version}}
    version: ^0.1.0
```

## Usage

```dart
import 'package:copilotkit_headless_flutter/copilotkit_headless_flutter.dart';

final actions = CopilotActionRegistry(
  actions: [
    CopilotAction(
      name: 'echo',
      parameters: const [
        CopilotActionParameter(
          name: 'text',
          type: CopilotActionParameterType.string,
        ),
      ],
      handler: (args, context) async {
        return CopilotActionResult(
          payload: {'echo': args['text']},
        );
      },
    ),
  ],
);
```

## Development

Run the package checks before tagging a release:

```sh
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
dart doc --dry-run .
```
