import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/src/agui/reducer/activity_reducer.dart';
import 'package:copilotkit_headless_flutter/src/agui/session/thread_session.dart';

import '../test_helpers/envelope_factory.dart';

void main() {
  group('ActivityReducer', () {
    test('updates activity view models from snapshots and deltas', () {
      const reducer = ActivityReducer();
      var session = ThreadSession.initial('thread-123');

      session = reducer.reduce(
        session,
        envelopeFromJson(<String, Object?>{
          'type': 'ACTIVITY_SNAPSHOT',
          'activities': <Object?>[
            <String, Object?>{
              'id': 'activity-1',
              'label': 'Search repository',
              'status': 'running',
            },
          ],
        }),
      );

      expect(session.activities['activity-1']?.label, 'Search repository');
      expect(session.activities['activity-1']?.status, 'running');

      session = reducer.reduce(
        session,
        envelopeFromJson(<String, Object?>{
          'type': 'ACTIVITY_DELTA',
          'delta': <String, Object?>{
            'id': 'activity-1',
            'status': 'completed',
            'summary': 'Found 2 matches',
          },
        }),
      );

      expect(session.activities['activity-1']?.status, 'completed');
      expect(session.activities['activity-1']?.summary, 'Found 2 matches');
    });

    test('accepts canonical message snapshots and patch deltas', () {
      const reducer = ActivityReducer();
      var session = ThreadSession.initial('thread-123');

      session = reducer.reduce(
        session,
        envelopeFromJson(<String, Object?>{
          'type': 'ACTIVITY_SNAPSHOT',
          'messageId': 'activity-1',
          'activityType': 'search_progress',
          'content': <String, Object?>{
            'label': 'Searching',
            'status': 'running',
            'progress': 0.4,
          },
        }),
      );
      session = reducer.reduce(
        session,
        envelopeFromJson(<String, Object?>{
          'type': 'ACTIVITY_DELTA',
          'messageId': 'activity-1',
          'activityType': 'search_progress',
          'patch': <Object?>[
            <String, Object?>{
              'op': 'replace',
              'path': '/progress',
              'value': 0.8,
            },
            <String, Object?>{
              'op': 'replace',
              'path': '/status',
              'value': 'completed',
            },
          ],
        }),
      );

      expect(session.activities['activity-1']?.label, 'Searching');
      expect(session.activities['activity-1']?.status, 'completed');
      expect(session.activities['activity-1']?.details['progress'], 0.8);
    });
  });
}
