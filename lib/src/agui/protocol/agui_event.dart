import 'agui_message.dart';
import 'agui_json.dart';

sealed class AgUiEvent {
  const AgUiEvent({required this.type, required this.rawJson});

  final String type;
  final Map<String, Object?> rawJson;

  static AgUiEvent fromJson(Map<String, Object?> json) {
    final normalized = normalizeObjectMap(json);
    final type = normalizeString(normalized['type']) ?? 'UNKNOWN';

    return switch (type) {
      'RUN_STARTED' => RunStartedEvent(
        rawJson: normalized,
        threadId: normalizeString(normalized['threadId']) ?? '',
        runId: normalizeString(normalized['runId']) ?? '',
      ),
      'MESSAGES_SNAPSHOT' => MessagesSnapshotEvent(
        rawJson: normalized,
        messages: normalizeObjectList(normalized['messages'])
            .map((item) => AgUiMessage.fromJson(normalizeObjectMap(item)))
            .toList(growable: false),
      ),
      'TEXT_MESSAGE_CONTENT' => TextMessageContentEvent(
        rawJson: normalized,
        messageId: normalizeString(normalized['messageId']) ?? '',
        delta: normalizeString(normalized['delta']) ?? '',
      ),
      'TOOL_CALL_START' => ToolCallStartEvent(
        rawJson: normalized,
        toolCallId: normalizeString(normalized['toolCallId']) ?? '',
        toolName:
            normalizeString(normalized['toolCallName']) ??
            normalizeString(normalized['toolName']) ??
            '',
      ),
      'STATE_SNAPSHOT' => StateSnapshotEvent(
        rawJson: normalized,
        snapshot: normalizeObjectMap(normalized['snapshot']),
      ),
      'ACTIVITY_DELTA' => ActivityDeltaEvent(
        rawJson: normalized,
        delta: normalizeObjectMap(normalized['delta']),
      ),
      'REASONING_SUMMARY' => ReasoningSummaryEvent(
        rawJson: normalized,
        summary: normalizeString(normalized['summary']) ?? '',
      ),
      'RAW' => RawAgUiEvent(
        rawJson: normalized,
        data: normalizeObjectMap(normalized['data']),
      ),
      'CUSTOM' => CustomAgUiEvent(
        rawJson: normalized,
        name: normalizeString(normalized['name']) ?? '',
        payload: normalizeObjectMap(normalized['payload']),
      ),
      _ => UnknownAgUiEvent(type: type, rawJson: normalized),
    };
  }
}

class RunStartedEvent extends AgUiEvent {
  const RunStartedEvent({
    required super.rawJson,
    required this.threadId,
    required this.runId,
  }) : super(type: 'RUN_STARTED');

  final String threadId;
  final String runId;
}

class MessagesSnapshotEvent extends AgUiEvent {
  const MessagesSnapshotEvent({required super.rawJson, required this.messages})
    : super(type: 'MESSAGES_SNAPSHOT');

  final List<AgUiMessage> messages;
}

class TextMessageContentEvent extends AgUiEvent {
  const TextMessageContentEvent({
    required super.rawJson,
    required this.messageId,
    required this.delta,
  }) : super(type: 'TEXT_MESSAGE_CONTENT');

  final String messageId;
  final String delta;
}

class ToolCallStartEvent extends AgUiEvent {
  const ToolCallStartEvent({
    required super.rawJson,
    required this.toolCallId,
    required this.toolName,
  }) : super(type: 'TOOL_CALL_START');

  final String toolCallId;
  final String toolName;
}

class StateSnapshotEvent extends AgUiEvent {
  const StateSnapshotEvent({required super.rawJson, required this.snapshot})
    : super(type: 'STATE_SNAPSHOT');

  final Map<String, Object?> snapshot;
}

class ActivityDeltaEvent extends AgUiEvent {
  const ActivityDeltaEvent({required super.rawJson, required this.delta})
    : super(type: 'ACTIVITY_DELTA');

  final Map<String, Object?> delta;
}

class ReasoningSummaryEvent extends AgUiEvent {
  const ReasoningSummaryEvent({required super.rawJson, required this.summary})
    : super(type: 'REASONING_SUMMARY');

  final String summary;
}

class RawAgUiEvent extends AgUiEvent {
  const RawAgUiEvent({required super.rawJson, required this.data})
    : super(type: 'RAW');

  final Map<String, Object?> data;
}

class CustomAgUiEvent extends AgUiEvent {
  const CustomAgUiEvent({
    required super.rawJson,
    required this.name,
    required this.payload,
  }) : super(type: 'CUSTOM');

  final String name;
  final Map<String, Object?> payload;
}

class UnknownAgUiEvent extends AgUiEvent {
  const UnknownAgUiEvent({required super.type, required super.rawJson});
}
