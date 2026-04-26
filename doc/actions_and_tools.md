# Actions and Frontend Tools

Copilot actions are the preferred public API for local tool behavior. Actions
describe a callable capability, expose a JSON schema to the agent, and
optionally execute in the Flutter client.

```dart
final actions = CopilotActionRegistry(
  actions: [
    CopilotAction(
      name: 'show_invoice',
      description: 'Open an invoice by ID.',
      parameters: const [
        CopilotActionParameter(
          name: 'invoiceId',
          type: CopilotActionParameterType.string,
        ),
      ],
      handler: (args, context) async {
        return CopilotActionResult(
          payload: {'opened': args['invoiceId']},
        );
      },
    ),
  ],
);
```

## Availability

`CopilotActionAvailabilityMode.enabled` exports and executes locally when
capabilities and permissions allow it.

`CopilotActionAvailabilityMode.disabled` keeps the action unavailable.

`CopilotActionAvailabilityMode.remote` exports the action definition to the
agent but prevents local execution. Use this when the backend owns execution.

## Follow-Up

When `followUp` is `true`, local tool results are appended as AG-UI tool
messages and sent back to the agent. When `false`, the tool call is completed
locally and no follow-up run is triggered.

## Error Payloads

The runloop reports stable error payloads for missing tools, unavailable
capabilities, missing permissions, remote-only calls, user-response gaps,
cancellation, and execution failures.
