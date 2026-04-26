import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/src/agui/reducer/shared_state_reducer.dart';
import 'package:copilotkit_headless_flutter/src/agui/session/shared_state_document.dart';
import 'package:copilotkit_headless_flutter/src/agui/session/thread_session.dart';

import '../test_helpers/envelope_factory.dart';

void main() {
  group('SharedStateReducer recovery', () {
    test('a fresh snapshot clears degraded status and restores confidence', () {
      const reducer = SharedStateReducer();
      var session =
          ThreadSession.initial(
            'thread-123',
            connectionStatus: ConnectionStatus.degraded,
          ).copyWith(
            sharedState: const SharedStateDocument(
              data: <String, Object?>{
                'draft': <String, Object?>{'status': 'pending'},
              },
            ),
            requiresSharedStateRecovery: true,
            sharedStateFailureReason: 'Patch failed at /draft/status.',
          );

      session = reducer.reduce(
        session,
        envelopeFromJson(<String, Object?>{
          'type': 'STATE_SNAPSHOT',
          'snapshot': <String, Object?>{
            'draft': <String, Object?>{
              'status': 'recovered',
              'warnings': <Object?>['fresh'],
            },
          },
        }, receivedAt: DateTime.utc(2026, 4, 18, 16)),
      );

      expect(session.connectionStatus, ConnectionStatus.online);
      expect(session.requiresSharedStateRecovery, isFalse);
      expect(session.sharedStateFailureReason, isNull);
      expect(session.sharedState.data, <String, Object?>{
        'draft': <String, Object?>{
          'status': 'recovered',
          'warnings': <Object?>['fresh'],
        },
      });
      expect(session.lastSharedStateRecoveredAt, DateTime.utc(2026, 4, 18, 16));
    });
  });
}
