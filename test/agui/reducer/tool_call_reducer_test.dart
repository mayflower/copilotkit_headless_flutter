import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/src/agui/reducer/tool_call_reducer.dart';
import 'package:copilotkit_headless_flutter/src/agui/session/thread_session.dart';

import '../test_helpers/envelope_factory.dart';

void main() {
  group('ToolCallReducer', () {
    test('progresses tool cards through start, args, end, and result', () {
      const reducer = ToolCallReducer();
      var session = ThreadSession.initial('thread-123');

      session = reducer.reduce(
        session,
        envelopeFromJson(<String, Object?>{
          'type': 'TOOL_CALL_START',
          'toolCallId': 'tool-1',
          'toolName': 'search_repo',
        }),
      );
      expect(session.toolCalls['tool-1']?.stage, ToolCallStage.started);

      session = reducer.reduce(
        session,
        envelopeFromJson(<String, Object?>{
          'type': 'TOOL_CALL_ARGS',
          'toolCallId': 'tool-1',
          'args': <String, Object?>{'query': 'budget'},
        }),
      );
      expect(session.toolCalls['tool-1']?.stage, ToolCallStage.arguments);
      expect(session.toolCalls['tool-1']?.arguments, <String, Object?>{
        'query': 'budget',
      });

      session = reducer.reduce(
        session,
        envelopeFromJson(<String, Object?>{
          'type': 'TOOL_CALL_END',
          'toolCallId': 'tool-1',
        }),
      );
      expect(session.toolCalls['tool-1']?.stage, ToolCallStage.ended);

      session = reducer.reduce(
        session,
        envelopeFromJson(<String, Object?>{
          'type': 'TOOL_CALL_RESULT',
          'toolCallId': 'tool-1',
          'result': <String, Object?>{'rows': 3},
        }),
      );

      expect(session.toolCalls['tool-1']?.stage, ToolCallStage.result);
      expect(session.toolCalls['tool-1']?.result, <String, Object?>{'rows': 3});
    });

    test('accepts canonical toolCallName and streamed argument deltas', () {
      const reducer = ToolCallReducer();
      var session = ThreadSession.initial('thread-123');

      session = reducer.reduce(
        session,
        envelopeFromJson(<String, Object?>{
          'type': 'TOOL_CALL_START',
          'toolCallId': 'tool-1',
          'toolCallName': 'confirmAction',
        }),
      );

      session = reducer.reduce(
        session,
        envelopeFromJson(<String, Object?>{
          'type': 'TOOL_CALL_ARGS',
          'toolCallId': 'tool-1',
          'delta': '{"title":"Confirm",',
        }),
      );
      session = reducer.reduce(
        session,
        envelopeFromJson(<String, Object?>{
          'type': 'TOOL_CALL_CHUNK',
          'toolCallId': 'tool-1',
          'delta': '"message":"Proceed?"}',
        }),
      );
      session = reducer.reduce(
        session,
        envelopeFromJson(<String, Object?>{
          'type': 'TOOL_CALL_END',
          'toolCallId': 'tool-1',
        }),
      );

      expect(session.toolCalls['tool-1']?.name, 'confirmAction');
      expect(session.toolCalls['tool-1']?.arguments, <String, Object?>{
        'title': 'Confirm',
        'message': 'Proceed?',
      });
    });
  });
}
