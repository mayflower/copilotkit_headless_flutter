# Roadmap

This roadmap tracks the path from extracted package to stable public API.

## 0.x Stabilization

- Keep AG-UI protocol and reducer behavior covered by fixtures.
- Expand CopilotKit-style frontend action parity.
- Harden generative UI and `renderAndWaitForResponse` flows.
- Improve CoAgent shared-state render patterns.
- Add more transport examples and backend contract tests.
- Publish tagged releases with migration notes.

## 1.0 Criteria

- Public API reviewed for naming, lifecycle semantics, and error payloads.
- Runnable example covers chat, tools, renderer UI, shared state, and HITL.
- CI, documentation, security policy, and release process are active.
- No downstream app imports from `src`.
- Compatibility matrix documents supported Dart, Flutter, AG-UI, and backend
  assumptions.

## Later

- Optional debug/observability companion package.
- More renderer widgets for common tool and state surfaces.
- Hosted pub publishing once package governance and release ownership are clear.
