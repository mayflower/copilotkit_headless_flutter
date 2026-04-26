# Migration from App-Local Code

Replace app-local imports with the package barrel:

```dart
import 'package:copilotkit_headless_flutter/copilotkit_headless_flutter.dart';
```

Remove app-local copies of portable code:

- AG-UI protocol models.
- AG-UI reducers.
- Thread session models and controller.
- Generic transport interfaces and HTTP/SSE transport.
- Copilot action, runloop, renderer, readable, runtime, and CoAgent state APIs.
- Generic frontend tool registry and executor.

Keep app-specific adapters in the app:

- Authenticated transport wrappers.
- Persistence repositories.
- State-management providers.
- Platform tools and permission UX.
- Product-specific debug surfaces.

After migration, scan downstream apps for imports from former local paths and
for imports from this package's `src` directory.
