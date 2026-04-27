import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/src/agui/protocol/agui_event_envelope.dart';
import 'package:copilotkit_headless_flutter/src/agui/session/thread_session.dart';
import 'package:copilotkit_headless_flutter/src/agui/session/thread_session_controller.dart';

import '../test_helpers/envelope_factory.dart';

void main() {
  group('ThreadSessionController', () {
    test('reduces a transport stream into stable thread view models', () async {
      final controller = ThreadSessionController();
      final baseTime = DateTime.utc(2026, 4, 18, 12);

      final states = await controller
          .bind(
            initialSession: ThreadSession.initial(
              'thread-123',
              connectionStatus: ConnectionStatus.reconnecting,
            ),
            events: Stream<AgUiEventEnvelope>.fromIterable(
              const <AgUiEventEnvelope>[],
            ),
          )
          .toList();

      expect(states, isEmpty);

      final replayedStates = await controller
          .bind(
            initialSession: ThreadSession.initial(
              'thread-123',
              connectionStatus: ConnectionStatus.reconnecting,
            ),
            events: Stream<AgUiEventEnvelope>.fromIterable(<AgUiEventEnvelope>[
              envelopeFromJson(<String, Object?>{
                'type': 'RUN_STARTED',
                'threadId': 'thread-123',
                'runId': 'run-1',
              }, receivedAt: baseTime),
              envelopeFromJson(<String, Object?>{
                'type': 'TEXT_MESSAGE_START',
                'messageId': 'assistant-1',
                'role': 'assistant',
              }, receivedAt: baseTime.add(const Duration(seconds: 1))),
              envelopeFromJson(<String, Object?>{
                'type': 'TEXT_MESSAGE_CONTENT',
                'messageId': 'assistant-1',
                'delta': 'Hi there',
              }, receivedAt: baseTime.add(const Duration(seconds: 2))),
              envelopeFromJson(<String, Object?>{
                'type': 'TEXT_MESSAGE_END',
                'messageId': 'assistant-1',
              }, receivedAt: baseTime.add(const Duration(seconds: 3))),
              envelopeFromJson(<String, Object?>{
                'type': 'TOOL_CALL_START',
                'toolCallId': 'tool-1',
                'toolCallName': 'search_repo',
              }, receivedAt: baseTime.add(const Duration(seconds: 4))),
              envelopeFromJson(<String, Object?>{
                'type': 'TOOL_CALL_ARGS',
                'toolCallId': 'tool-1',
                'args': <String, Object?>{'query': 'budget'},
              }, receivedAt: baseTime.add(const Duration(seconds: 5))),
              envelopeFromJson(<String, Object?>{
                'type': 'TOOL_CALL_RESULT',
                'toolCallId': 'tool-1',
                'result': <String, Object?>{'rows': 3},
              }, receivedAt: baseTime.add(const Duration(seconds: 6))),
              envelopeFromJson(<String, Object?>{
                'type': 'ACTIVITY_SNAPSHOT',
                'messageId': 'activity-1',
                'activityType': 'task',
                'content': <String, Object?>{
                  'label': 'Search repository',
                  'status': 'running',
                },
              }, receivedAt: baseTime.add(const Duration(seconds: 7))),
              envelopeFromJson(<String, Object?>{
                'type': 'ACTIVITY_DELTA',
                'messageId': 'activity-1',
                'activityType': 'task',
                'patch': <Object?>[
                  <String, Object?>{
                    'op': 'replace',
                    'path': '/status',
                    'value': 'completed',
                  },
                ],
              }, receivedAt: baseTime.add(const Duration(seconds: 8))),
              envelopeFromJson(<String, Object?>{
                'type': 'RUN_FINISHED',
                'threadId': 'thread-123',
                'runId': 'run-1',
              }, receivedAt: baseTime.add(const Duration(seconds: 9))),
            ]),
          )
          .toList();

      final session = replayedStates.last;
      expect(session.connectionStatus, ConnectionStatus.online);
      expect(session.runStatus, RunStatus.completed);
      expect(session.messages.single.text, 'Hi there');
      expect(session.toolCalls['tool-1']?.result, <String, Object?>{'rows': 3});
      expect(session.activities['activity-1']?.status, 'completed');
      expect(session.eventLog, hasLength(10));
      expect(session.lastEventAt, baseTime.add(const Duration(seconds: 9)));
    });
  });
}
