import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/copilotkit_headless_flutter.dart';

void main() {
  test('exports only available readable entries with metadata', () {
    final registry = CopilotReadableRegistry(
      entries: const <CopilotReadable>[
        CopilotReadable(
          key: 'customer',
          description: 'Current customer',
          category: 'crm',
          value: <String, Object?>{'id': 'customer-1'},
        ),
        CopilotReadable(
          key: 'draft',
          description: 'Draft',
          parentKey: 'customer',
          available: false,
          value: <String, Object?>{'id': 'draft-1'},
        ),
      ],
    );

    final entries = registry.toContextEntries();

    expect(entries.map((entry) => entry.key), <String>['customer']);
    expect(entries.single.value, <String, Object?>{
      'description': 'Current customer',
      'value': <String, Object?>{'id': 'customer-1'},
      'category': 'crm',
    });
  });
}
