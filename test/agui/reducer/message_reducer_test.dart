import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/src/agui/protocol/agui_message.dart';
import 'package:copilotkit_headless_flutter/src/agui/reducer/message_reducer.dart';
import 'package:copilotkit_headless_flutter/src/agui/session/thread_session.dart';

import '../test_helpers/envelope_factory.dart';

void main() {
  group('MessageReducer', () {
    test(
      'assembles assistant text streams and replaces transcript snapshots',
      () {
        const reducer = MessageReducer();
        var session = ThreadSession.initial('thread-123');

        session = reducer.reduce(
          session,
          envelopeFromJson(<String, Object?>{
            'type': 'TEXT_MESSAGE_START',
            'messageId': 'assistant-1',
            'role': 'assistant',
          }),
        );
        session = reducer.reduce(
          session,
          envelopeFromJson(<String, Object?>{
            'type': 'TEXT_MESSAGE_CONTENT',
            'messageId': 'assistant-1',
            'delta': 'Hello',
          }),
        );
        session = reducer.reduce(
          session,
          envelopeFromJson(<String, Object?>{
            'type': 'TEXT_MESSAGE_CONTENT',
            'messageId': 'assistant-1',
            'delta': ' there',
          }),
        );
        session = reducer.reduce(
          session,
          envelopeFromJson(<String, Object?>{
            'type': 'TEXT_MESSAGE_END',
            'messageId': 'assistant-1',
          }),
        );

        expect(session.messages, hasLength(1));
        expect(session.messages.single.id, 'assistant-1');
        expect(session.messages.single.role, AgUiMessageRole.assistant);
        expect(session.messages.single.text, 'Hello there');
        expect(session.messages.single.isStreaming, isFalse);

        session = reducer.reduce(
          session,
          envelopeFromJson(<String, Object?>{
            'type': 'MESSAGES_SNAPSHOT',
            'messages': <Object?>[
              <String, Object?>{
                'id': 'snapshot-1',
                'role': 'assistant',
                'content': 'Canonical transcript',
              },
            ],
          }),
        );

        expect(session.messages, hasLength(1));
        expect(session.messages.single.id, 'snapshot-1');
        expect(session.messages.single.text, 'Canonical transcript');
      },
    );
  });
}
