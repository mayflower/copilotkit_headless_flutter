import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/src/agui/reducer/debug_reducer.dart';
import 'package:copilotkit_headless_flutter/src/agui/session/thread_session.dart';

import '../test_helpers/envelope_factory.dart';

void main() {
  group('DebugReducer', () {
    test('keeps raw, custom, unknown, and malformed events inspectable', () {
      const reducer = DebugReducer();
      var session = ThreadSession.initial('thread-123');

      session = reducer.reduce(
        session,
        envelopeFromJson(<String, Object?>{
          'type': 'RAW',
          'data': <String, Object?>{'source': 'transport'},
        }),
      );
      session = reducer.reduce(
        session,
        envelopeFromJson(<String, Object?>{
          'type': 'CUSTOM',
          'name': 'experimental',
          'payload': <String, Object?>{'value': 1},
        }),
      );
      session = reducer.reduce(
        session,
        envelopeFromJson(<String, Object?>{
          'type': 'SOMETHING_NEW',
          'value': true,
        }),
      );
      session = reducer.reduce(
        session,
        malformedEnvelope(
          rawPayload: '{"type":"RUN_STARTED"',
          sseEventName: 'RUN_STARTED',
        ),
      );

      expect(session.debugEvents, hasLength(4));
      expect(session.debugEvents[0].type, 'RAW');
      expect(session.debugEvents[1].type, 'CUSTOM');
      expect(session.debugEvents[2].type, 'SOMETHING_NEW');
      expect(session.debugEvents[3].decodeErrorMessage, isNotNull);
    });
  });
}
