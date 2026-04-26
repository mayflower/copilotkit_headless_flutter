# CoAgent Shared State

CoAgent state is represented by `ThreadSession.sharedState`. The package keeps
state updates on the AG-UI reducer path so snapshots, patches, recovery, and
debug logs remain consistent.

Use the public shared-state APIs instead of reading reducer internals directly.

Typical app responsibilities:

- Render current state in a state surface.
- Patch state through public APIs.
- Subscribe UI to agent, node, status, or state changes.
- Persist state only when the app has an explicit storage policy.

State payloads should be small, serializable, and safe to expose in client-side
debug tools. Avoid secrets and large documents.
