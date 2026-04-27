import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/src/agui/protocol/agui_event.dart';

import 'agui_fixture_loader.dart';

void main() {
  group('AgUiEvent.fromJson', () {
    test('decodes lifecycle events to typed variants', () async {
      final event = AgUiEvent.fromJson(
        await loadAgUiFixture('run_started.json'),
      );

      expect(event, isA<RunStartedEvent>());
      final typed = event as RunStartedEvent;
      expect(typed.threadId, 'thread_demo');
      expect(typed.runId, 'run_demo');
    });

    test('decodes message snapshot and streaming text events', () async {
      final snapshotEvent = AgUiEvent.fromJson(
        await loadAgUiFixture('messages_snapshot.json'),
      );
      final streamingEvent = AgUiEvent.fromJson(
        await loadAgUiFixture('text_message_content.json'),
      );

      expect(snapshotEvent, isA<MessagesSnapshotEvent>());
      expect(streamingEvent, isA<TextMessageContentEvent>());
    });

    test('decodes tool events to typed variants', () async {
      final event = AgUiEvent.fromJson(
        await loadAgUiFixture('tool_call_start.json'),
      );

      expect(event, isA<ToolCallStartEvent>());
      final typed = event as ToolCallStartEvent;
      expect(typed.toolCallId, 'tool_call_1');
      expect(typed.toolCallName, 'pick_file');
    });

    test('decodes state events to typed variants', () async {
      final event = AgUiEvent.fromJson(
        await loadAgUiFixture('state_snapshot.json'),
      );

      expect(event, isA<StateSnapshotEvent>());
      final typed = event as StateSnapshotEvent;
      expect(typed.snapshot['selectedDraftId'], 'draft_42');
    });

    test('decodes activity events to typed variants', () async {
      final event = AgUiEvent.fromJson(
        await loadAgUiFixture('activity_delta.json'),
      );

      expect(event, isA<ActivityDeltaEvent>());
      final typed = event as ActivityDeltaEvent;
      expect(typed.messageId, 'activity_1');
      expect(typed.activityType, 'task');
      expect(typed.patch, hasLength(2));
    });

    test('decodes reasoning events to typed variants', () async {
      final event = AgUiEvent.fromJson(
        await loadAgUiFixture('reasoning_summary.json'),
      );

      expect(event, isA<ReasoningMessageContentEvent>());
      final typed = event as ReasoningMessageContentEvent;
      expect(typed.messageId, 'reasoning_1');
      expect(
        typed.delta,
        'Compared the latest draft against the uploaded contract.',
      );
    });

    test('decodes raw and custom events without discarding payloads', () async {
      final rawEvent = AgUiEvent.fromJson(await loadAgUiFixture('raw.json'));
      final customEvent = AgUiEvent.fromJson(
        await loadAgUiFixture('custom.json'),
      );

      expect(rawEvent, isA<RawAgUiEvent>());
      expect(customEvent, isA<CustomAgUiEvent>());

      final typedRaw = rawEvent as RawAgUiEvent;
      final typedCustom = customEvent as CustomAgUiEvent;
      expect(typedRaw.data['traceId'], 'trace_123');
      expect(typedRaw.event, isA<Map<String, Object?>>());
      expect(typedRaw.source, isNull);
      expect(typedCustom.name, 'MOBILE_HINT');
      expect(typedCustom.payload['hint'], 'focusComposer');
      expect(typedCustom.value, isA<Map<String, Object?>>());
    });

    test('decodes current raw custom and finished result fields', () {
      final raw =
          AgUiEvent.fromJson(<String, Object?>{
                'type': 'RAW',
                'event': <String, Object?>{'traceId': 'trace_456'},
                'source': 'agent',
              })
              as RawAgUiEvent;
      expect(raw.event, <String, Object?>{'traceId': 'trace_456'});
      expect(raw.source, 'agent');
      expect(raw.data['traceId'], 'trace_456');

      final custom =
          AgUiEvent.fromJson(<String, Object?>{
                'type': 'CUSTOM',
                'name': 'MOBILE_HINT',
                'value': <String, Object?>{'hint': 'openPanel'},
              })
              as CustomAgUiEvent;
      expect(custom.name, 'MOBILE_HINT');
      expect(custom.value, <String, Object?>{'hint': 'openPanel'});
      expect(custom.payload['hint'], 'openPanel');

      final finished =
          AgUiEvent.fromJson(<String, Object?>{
                'type': 'RUN_FINISHED',
                'threadId': 'thread_demo',
                'runId': 'run_demo',
                'result': <String, Object?>{'status': 'ok'},
              })
              as RunFinishedEvent;
      expect(finished.result, <String, Object?>{'status': 'ok'});
    });

    test('preserves unknown events instead of dropping them', () async {
      final event = AgUiEvent.fromJson(await loadAgUiFixture('unknown.json'));

      expect(event, isA<UnknownAgUiEvent>());
      final typed = event as UnknownAgUiEvent;
      expect(typed.type, 'SOMETHING_FUTURE');
      expect(typed.rawJson['futureField'], 7);
    });
  });
}
