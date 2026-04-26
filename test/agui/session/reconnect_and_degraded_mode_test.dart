import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/src/agui/protocol/agui_message.dart';
import 'package:copilotkit_headless_flutter/src/agui/session/thread_session.dart';
import 'package:copilotkit_headless_flutter/src/agui/session/thread_session_connection_coordinator.dart';

void main() {
  group('ThreadSessionConnectionCoordinator', () {
    test('stream loss moves a healthy session into reconnecting mode', () {
      const coordinator = ThreadSessionConnectionCoordinator();
      final session = ThreadSession.initial('thread-123').copyWith(
        runStatus: RunStatus.running,
        messages: const <UiMessage>[
          UiMessage(
            id: 'assistant-1',
            role: AgUiMessageRole.assistant,
            text: 'Working on it',
          ),
        ],
      );

      final updated = coordinator.onStreamDisconnected(
        session,
        message: 'stream lost during run',
      );

      expect(updated.connectionStatus, ConnectionStatus.reconnecting);
      expect(updated.runStatus, RunStatus.running);
      expect(updated.messages.single.text, 'Working on it');
      expect(updated.lastErrorMessage, contains('stream lost'));
    });

    test(
      'reconnect success clears transport errors but keeps shared-state degraded sessions degraded',
      () {
        const coordinator = ThreadSessionConnectionCoordinator();
        final session =
            ThreadSession.initial(
              'thread-123',
              connectionStatus: ConnectionStatus.degraded,
            ).copyWith(
              requiresSharedStateRecovery: true,
              sharedStateFailureReason: 'patch failed',
              lastErrorMessage: 'stream lost during run',
            );

        final updated = coordinator.onReconnectSucceeded(
          session,
          recoveredAt: DateTime.utc(2026, 4, 18, 12, 30),
        );

        expect(updated.connectionStatus, ConnectionStatus.degraded);
        expect(updated.requiresSharedStateRecovery, isTrue);
        expect(updated.lastErrorMessage, isNull);
      },
    );
  });
}
