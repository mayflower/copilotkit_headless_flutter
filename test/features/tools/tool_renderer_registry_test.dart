import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/src/features/tools/application/tool_renderer_registry.dart';

void main() {
  group('ToolRendererRegistry', () {
    test('unknown tools fall back to the default renderer path', () {
      const registry = ToolRendererRegistry(
        defaultRenderer: ToolRenderer(id: 'default-card'),
        renderers: <String, ToolRenderer>{
          'copy_to_clipboard': ToolRenderer(id: 'clipboard-card'),
        },
      );

      expect(registry.resolve('copy_to_clipboard').id, 'clipboard-card');
      expect(registry.resolve('unmodeled_tool').id, 'default-card');
    });
  });
}
