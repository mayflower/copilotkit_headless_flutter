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
      expect(typed.toolName, 'pick_file');
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
      expect(typed.delta['status'], 'running');
    });

    test('decodes reasoning events to typed variants', () async {
      final event = AgUiEvent.fromJson(
        await loadAgUiFixture('reasoning_summary.json'),
      );

      expect(event, isA<ReasoningSummaryEvent>());
      final typed = event as ReasoningSummaryEvent;
      expect(
        typed.summary,
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
      expect(typedCustom.name, 'MOBILE_HINT');
      expect(typedCustom.payload['hint'], 'focusComposer');
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
