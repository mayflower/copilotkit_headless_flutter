import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/copilotkit_headless_flutter.dart';

void main() {
  test('reads, sets and patches scoped coagent state', () {
    var notifications = 0;
    final controller = CopilotCoAgentStateController<Map<String, Object?>>(
      scope: const CopilotCoAgentScope(agentId: 'agent-a', nodeId: 'draft'),
      document: const SharedStateDocument(
        data: <String, Object?>{
          'agent-a': <String, Object?>{
            'draft': <String, Object?>{'title': 'Old'},
          },
        },
      ),
      decoder: (data) => data,
      encoder: (value) => value,
    )..addListener(() => notifications += 1);

    expect(controller.value, <String, Object?>{'title': 'Old'});

    final setDocument = controller.setValue(<String, Object?>{'title': 'New'});
    expect(
      (setDocument.data['agent-a']! as Map<String, Object?>)['draft'],
      <String, Object?>{'title': 'New'},
    );

    final patchedDocument = controller.patch(const <Object?>[
      <String, Object?>{'op': 'add', 'path': '/status', 'value': 'ready'},
    ]);
    expect(
      (patchedDocument.data['agent-a']! as Map<String, Object?>)['draft'],
      <String, Object?>{'title': 'New', 'status': 'ready'},
    );
    expect(notifications, 2);
  });
}
