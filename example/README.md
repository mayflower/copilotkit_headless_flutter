# Example

This directory contains small integration snippets for apps that consume the
package. The production app should provide its own transport, auth, persistence,
and dependency-injection adapters.

```dart
import 'package:copilotkit_headless_flutter/copilotkit_headless_flutter.dart';

final actionRegistry = CopilotActionRegistry(
  actions: [
    CopilotAction(
      name: 'selectItem',
      parameters: const [
        CopilotActionParameter(
          name: 'id',
          type: CopilotActionParameterType.string,
        ),
      ],
      handler: (args, context) async {
        return CopilotActionResult(payload: {'selected': args['id']});
      },
    ),
  ],
);
```
