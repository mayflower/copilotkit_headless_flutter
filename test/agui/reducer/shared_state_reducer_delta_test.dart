import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/src/agui/reducer/shared_state_reducer.dart';
import 'package:copilotkit_headless_flutter/src/agui/session/shared_state_document.dart';
import 'package:copilotkit_headless_flutter/src/agui/session/thread_session.dart';

import '../test_helpers/envelope_factory.dart';

void main() {
  group('SharedStateReducer delta', () {
    test('applies RFC-6902 patches in order', () {
      const reducer = SharedStateReducer();
      var session = ThreadSession.initial('thread-123').copyWith(
        sharedState: const SharedStateDocument(
          data: <String, Object?>{
            'draft': <String, Object?>{
              'status': 'pending',
              'warnings': <Object?>['old'],
            },
          },
        ),
      );

      session = reducer.reduce(
        session,
        envelopeFromJson(<String, Object?>{
          'type': 'STATE_DELTA',
          'patch': <Object?>[
            <String, Object?>{
              'op': 'replace',
              'path': '/draft/status',
              'value': 'review_required',
            },
            <String, Object?>{
              'op': 'add',
              'path': '/draft/warnings/-',
              'value': 'Summenabweichung erkannt',
            },
          ],
        }, receivedAt: DateTime.utc(2026, 4, 18, 14)),
      );

      expect(session.sharedState.data, <String, Object?>{
        'draft': <String, Object?>{
          'status': 'review_required',
          'warnings': <Object?>['old', 'Summenabweichung erkannt'],
        },
      });
      expect(session.sharedState.lastDeltaAt, DateTime.utc(2026, 4, 18, 14));
      expect(session.requiresSharedStateRecovery, isFalse);
    });

    test('accepts canonical delta field and advanced RFC-6902 operations', () {
      const reducer = SharedStateReducer();
      var session = ThreadSession.initial('thread-123').copyWith(
        sharedState: const SharedStateDocument(
          data: <String, Object?>{
            'draft': <String, Object?>{
              'status': 'pending',
              'warnings': <Object?>['old'],
              'copyFrom': <String, Object?>{'value': 7},
            },
          },
        ),
      );

      session = reducer.reduce(
        session,
        envelopeFromJson(<String, Object?>{
          'type': 'STATE_DELTA',
          'delta': <Object?>[
            <String, Object?>{
              'op': 'test',
              'path': '/draft/status',
              'value': 'pending',
            },
            <String, Object?>{
              'op': 'copy',
              'from': '/draft/copyFrom',
              'path': '/draft/copied',
            },
            <String, Object?>{
              'op': 'move',
              'from': '/draft/warnings/0',
              'path': '/draft/firstWarning',
            },
          ],
        }),
      );

      expect(session.requiresSharedStateRecovery, isFalse);
      expect(session.sharedState.data['draft'], <String, Object?>{
        'status': 'pending',
        'warnings': <Object?>[],
        'copyFrom': <String, Object?>{'value': 7},
        'copied': <String, Object?>{'value': 7},
        'firstWarning': 'old',
      });
    });
  });
}
