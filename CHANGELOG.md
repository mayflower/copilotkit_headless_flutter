## Unreleased

* Aligned AG-UI protocol models with the official upstream shapes: context
  entries, tool definitions, multimodal input sources, activity patches,
  reasoning events, tool-call events, and camelCase transport payloads.
* Added typed accessors for current AG-UI RAW/CUSTOM payload fields and
  RUN_FINISHED results while retaining legacy data/payload accessors.
* Removed mobile-specific protocol aliases from outbound AG-UI HTTP transport
  requests and reducer handling.

## 0.1.0

* Switched package licensing to The MIT License.
* Added CI, OpenSSF Scorecard, Dependabot, issue templates, pull request
  template, security policy, contribution guide, support guide, code of
  conduct, roadmap, and package documentation.
* Added a runnable example app with a mock AG-UI transport and local frontend
  tool runloop demonstration.
* Added package metadata for repository, issue tracker, homepage, and topics.
* Added local quality targets and GitHub Actions checks for package scoring,
  dependency freshness, Markdown linting, workflow linting, workflow security,
  dependency review, coverage, and secret scanning.
* Initial private package extraction from `maistack_mobile`.
* Added AG-UI protocol, reducer, session, generic HTTP transport, frontend tool,
  Copilot action, renderer registry, runloop, and CoAgent state APIs.
