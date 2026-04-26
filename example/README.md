# CopilotKit Headless Flutter Example

This example runs against an in-process mock AG-UI agent. It shows:

- `CopilotHeadlessChatController`
- `CopilotActionRegistry`
- local frontend tool execution
- tool-result follow-up to the agent
- shared-state rendering

Run it with:

```sh
flutter pub get
flutter run -d chrome
```

Or validate it with:

```sh
flutter analyze
flutter test
```
