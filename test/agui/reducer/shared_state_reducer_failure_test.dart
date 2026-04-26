import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/src/agui/reducer/shared_state_reducer.dart';
import 'package:copilotkit_headless_flutter/src/agui/session/shared_state_document.dart';
import 'package:copilotkit_headless_flutter/src/agui/session/thread_session.dart';

import '../test_helpers/envelope_factory.dart';

void main() {
  group('SharedStateReducer failure', () {
    test(
      'preserves the last readable state and marks the session degraded',
      () {
        const reducer = SharedStateReducer();
        final previousDocument = const SharedStateDocument(
          data: <String, Object?>{
            'draft': <String, Object?>{'status': 'pending'},
          },
        );
        var session = ThreadSession.initial(
          'thread-123',
        ).copyWith(sharedState: previousDocument);

        session = reducer.reduce(
          session,
          envelopeFromJson(<String, Object?>{
            'type': 'STATE_DELTA',
            'patch': <Object?>[
              <String, Object?>{
                'op': 'replace',
                'path': '/draft/missing/value',
                'value': 'boom',
              },
            ],
          }, receivedAt: DateTime.utc(2026, 4, 18, 15)),
        );

        expect(session.sharedState.data, previousDocument.data);
        expect(session.connectionStatus, ConnectionStatus.degraded);
        expect(session.requiresSharedStateRecovery, isTrue);
        expect(
          session.sharedStateFailureReason,
          contains('/draft/missing/value'),
        );
      },
    );
  });
}
