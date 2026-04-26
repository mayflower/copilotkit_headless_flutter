import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/src/agui/reducer/shared_state_reducer.dart';
import 'package:copilotkit_headless_flutter/src/agui/session/shared_state_document.dart';
import 'package:copilotkit_headless_flutter/src/agui/session/thread_session.dart';

import '../test_helpers/envelope_factory.dart';

void main() {
  group('SharedStateReducer snapshot', () {
    test('replaces the full shared-state document', () {
      const reducer = SharedStateReducer();
      var session = ThreadSession.initial('thread-123').copyWith(
        sharedState: const SharedStateDocument(
          data: <String, Object?>{
            'draft': <String, Object?>{'status': 'pending'},
            'oldOnly': true,
          },
        ),
        requiresSharedStateRecovery: true,
        sharedStateFailureReason: 'Previous patch failure.',
      );

      session = reducer.reduce(
        session,
        envelopeFromJson(<String, Object?>{
          'type': 'STATE_SNAPSHOT',
          'snapshot': <String, Object?>{
            'draft': <String, Object?>{'status': 'approved'},
            'warnings': <Object?>['reviewed'],
          },
        }, receivedAt: DateTime.utc(2026, 4, 18, 13)),
      );

      expect(session.sharedState.data, <String, Object?>{
        'draft': <String, Object?>{'status': 'approved'},
        'warnings': <Object?>['reviewed'],
      });
      expect(session.sharedState.data.containsKey('oldOnly'), isFalse);
      expect(session.requiresSharedStateRecovery, isFalse);
      expect(session.sharedStateFailureReason, isNull);
      expect(session.lastSharedStateRecoveredAt, DateTime.utc(2026, 4, 18, 13));
    });
  });
}
