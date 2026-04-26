# Generative UI

Generative UI maps tool calls to Flutter widgets. The headless package owns the
registry and lifecycle state; the consuming application decides how to present
widgets in chat, side panels, sheets, or review flows.

Use render modes to describe the lifecycle:

- `CopilotActionRenderMode.none`: execute without custom UI.
- `CopilotActionRenderMode.render`: render UI while the tool call is visible.
- `CopilotActionRenderMode.renderAndWaitForResponse`: render UI, wait for user
  response, then continue the agent run.

Unknown tools should still be shown through a generic fallback renderer in the
app so debugging remains possible.

## Human in the Loop

For `renderAndWaitForResponse`, wire `CopilotActionResponseCoordinator` into
the controller or runloop. The renderer presents approve, edit, reject, or
custom response controls, then completes the coordinator with a structured
payload.

```dart
coordinator.complete(
  toolCallId,
  {'approved': true, 'comment': 'Looks good'},
);
```

That payload becomes the tool result and can be sent back to the agent when the
tool has `followUp: true`.
