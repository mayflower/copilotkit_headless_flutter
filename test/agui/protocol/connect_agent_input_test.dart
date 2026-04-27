import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/src/agui/protocol/connect_agent_input.dart';

void main() {
  group('ConnectAgentInput', () {
    test('serializes the official AG-UI connect input fields', () {
      const input = ConnectAgentInput(threadId: 'thread-123');

      expect(input.toJson(), <String, Object?>{'threadId': 'thread-123'});
    });
  });
}
