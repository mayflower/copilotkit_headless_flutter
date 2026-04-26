# CopilotKit Headless Flutter

[![CI](https://github.com/mayflower/copilotkit_headless_flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/mayflower/copilotkit_headless_flutter/actions/workflows/ci.yml)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/mayflower/copilotkit_headless_flutter/badge)](https://securityscorecards.dev/viewer/?uri=github.com%2Fmayflower%2Fcopilotkit_headless_flutter)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Headless CopilotKit-style Flutter APIs over AG-UI. The package provides the
portable agent protocol, reducers, session controller, local frontend tools,
tool runloop, generative UI renderer registries, and CoAgent shared-state APIs.

This package is intentionally transport- and app-agnostic. App-specific auth,
storage, state-management providers, mobile-edge clients, and platform tools
stay in the consuming application as adapters.

## What You Get

- AG-UI protocol models, event decoding, reducers, and session state.
- Generic `AgentTransport` interfaces plus HTTP/SSE transport primitives.
- `CopilotAction` and `FrontendTool` APIs for local and remote tools.
- Tool runloop with follow-up semantics and stable error payloads.
- Renderer registries for generative UI and human-in-the-loop flows.
- CoAgent shared-state helpers over `ThreadSession.sharedState`.

## What Stays in Your App

- Authentication, tenant selection, and product configuration.
- App database persistence.
- Riverpod, Bloc, Provider, or other state-management adapters.
- Platform tools such as clipboard, share sheets, maps, files, and permissions.
- Product-specific debug overlays and UI shells.

## Install

Add the package from GitHub:

```yaml
dependencies:
  copilotkit_headless_flutter:
    git:
      url: https://github.com/mayflower/copilotkit_headless_flutter.git
```

For reproducible builds, pin a release tag:

```yaml
dependencies:
  copilotkit_headless_flutter:
    git:
      url: git@github.com:mayflower/copilotkit_headless_flutter.git
      tag_pattern: v{{version}}
    version: ^0.1.0
```

When the package is published to pub.dev, prefer the normal hosted dependency
syntax from the package page.

## Quick Start

```dart
import 'package:copilotkit_headless_flutter/copilotkit_headless_flutter.dart';

final actions = CopilotActionRegistry(
  actions: [
    CopilotAction(
      name: 'echo',
      description: 'Echo text back from the Flutter client.',
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

final controller = CopilotHeadlessChatController(
  transport: AgUiHttpTransport(
    config: AgUiTransportConfig(endpoint: Uri.parse('https://example.test/agui')),
  ),
  runtime: const CopilotRuntimeConfig(threadId: 'thread-1'),
  actionRegistry: actions,
);

await controller.submitUserMessage('Say hello and use the echo tool.');
```

See [example/lib/main.dart](example/lib/main.dart) for a runnable local mock
agent that demonstrates chat, frontend tool execution, follow-up messages, and
shared state without a backend.

## Documentation

- [Architecture](docs/architecture.md)
- [Actions and frontend tools](docs/actions_and_tools.md)
- [Generative UI and HITL](docs/generative_ui.md)
- [CoAgent shared state](docs/coagent_state.md)
- [Migration from app-local code](docs/migration.md)
- [Release process](docs/release_process.md)
- [Roadmap](ROADMAP.md)

## Compatibility

| Surface | Status |
| --- | --- |
| Dart SDK | `^3.11.5` |
| Flutter | Package API supports Flutter clients; CI uses stable Flutter |
| AG-UI | AG-UI remains the wire protocol |
| CopilotKit | Structural parity for headless actions, tools, renderers, and shared state |
| Distribution | Public GitHub repository; pub.dev publishing workflow included |

## Development

Run the package checks before opening a PR or tagging a release:

```sh
make package-check
```

Run the example checks separately:

```sh
make example-check
```

Run the broader local quality suite when touching workflows, documentation, or
release metadata:

```sh
make quality
make pana
make pub-outdated
```

`make quality` expects `actionlint`, `zizmor`, `gitleaks`, and Node's `npx` to
be installed locally. CI installs or runs those tools in GitHub Actions.

## Community

- Read [CONTRIBUTING.md](CONTRIBUTING.md) before proposing changes.
- Follow [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) in project spaces.
- Report vulnerabilities through [SECURITY.md](SECURITY.md).
- Use [SUPPORT.md](SUPPORT.md) for issue routing.

## License

This package is available under [The MIT License](LICENSE).
