import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/src/agui/reducer/reasoning_reducer.dart';
import 'package:copilotkit_headless_flutter/src/agui/session/thread_session.dart';

import '../test_helpers/envelope_factory.dart';

void main() {
  group('ReasoningReducer', () {
    test('streams reasoning text and stores encrypted values opaquely', () {
      const reducer = ReasoningReducer();
      var session = ThreadSession.initial('thread-123');

      session = reducer.reduce(
        session,
        envelopeFromJson(<String, Object?>{
          'type': 'REASONING_START',
          'messageId': 'reasoning-1',
        }),
      );
      session = reducer.reduce(
        session,
        envelopeFromJson(<String, Object?>{
          'type': 'REASONING_MESSAGE_CONTENT',
          'messageId': 'reasoning-1',
          'delta': 'Checking ',
        }),
      );
      session = reducer.reduce(
        session,
        envelopeFromJson(<String, Object?>{
          'type': 'REASONING_MESSAGE_CHUNK',
          'messageId': 'reasoning-1',
          'delta': 'sources',
        }),
      );
      session = reducer.reduce(
        session,
        envelopeFromJson(<String, Object?>{
          'type': 'REASONING_ENCRYPTED_VALUE',
          'entityId': 'reasoning-1',
          'subtype': 'message',
          'encryptedValue': 'opaque',
        }),
      );
      session = reducer.reduce(
        session,
        envelopeFromJson(<String, Object?>{
          'type': 'REASONING_END',
          'messageId': 'reasoning-1',
        }),
      );

      final reasoning = session.reasoning['reasoning-1'];
      expect(reasoning?.text, 'Checking sources');
      expect(reasoning?.stage, ReasoningStage.ended);
      expect(reasoning?.encryptedValues['message'], 'opaque');
    });
  });
}
