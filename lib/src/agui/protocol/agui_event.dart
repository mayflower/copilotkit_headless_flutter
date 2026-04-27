import 'agui_json.dart';
import 'agui_message.dart';

sealed class AgUiEvent {
  const AgUiEvent({required this.type, required this.rawJson});

  final String type;
  final Map<String, Object?> rawJson;

  static AgUiEvent fromJson(Map<String, Object?> json) {
    final normalized = normalizeObjectMap(json);
    final type = normalizeString(normalized['type']) ?? 'UNKNOWN';

    return switch (type) {
      'TEXT_MESSAGE_START' => TextMessageStartEvent(
        rawJson: normalized,
        messageId: normalizeString(normalized['messageId']) ?? '',
        role: normalizeString(normalized['role']) ?? 'assistant',
        name: normalizeString(normalized['name']),
      ),
      'TEXT_MESSAGE_CONTENT' => TextMessageContentEvent(
        rawJson: normalized,
        messageId: normalizeString(normalized['messageId']) ?? '',
        delta: normalizeString(normalized['delta']) ?? '',
      ),
      'TEXT_MESSAGE_END' => TextMessageEndEvent(
        rawJson: normalized,
        messageId: normalizeString(normalized['messageId']) ?? '',
      ),
      'TEXT_MESSAGE_CHUNK' => TextMessageChunkEvent(
        rawJson: normalized,
        messageId: normalizeString(normalized['messageId']) ?? '',
        role: normalizeString(normalized['role']),
        delta: normalizeString(normalized['delta']),
        name: normalizeString(normalized['name']),
      ),
      'TOOL_CALL_START' => ToolCallStartEvent(
        rawJson: normalized,
        toolCallId: normalizeString(normalized['toolCallId']) ?? '',
        toolCallName: normalizeString(normalized['toolCallName']) ?? '',
        parentMessageId: normalizeString(normalized['parentMessageId']),
      ),
      'TOOL_CALL_ARGS' => ToolCallArgsEvent(
        rawJson: normalized,
        toolCallId: normalizeString(normalized['toolCallId']) ?? '',
        delta: normalizeString(normalized['delta']) ?? '',
      ),
      'TOOL_CALL_END' => ToolCallEndEvent(
        rawJson: normalized,
        toolCallId: normalizeString(normalized['toolCallId']) ?? '',
      ),
      'TOOL_CALL_CHUNK' => ToolCallChunkEvent(
        rawJson: normalized,
        toolCallId: normalizeString(normalized['toolCallId']),
        toolCallName: normalizeString(normalized['toolCallName']),
        parentMessageId: normalizeString(normalized['parentMessageId']),
        delta: normalizeString(normalized['delta']),
      ),
      'TOOL_CALL_RESULT' => ToolCallResultEvent(
        rawJson: normalized,
        messageId: normalizeString(normalized['messageId']) ?? '',
        toolCallId: normalizeString(normalized['toolCallId']) ?? '',
        content: normalizeString(normalized['content']) ?? '',
        role: normalizeString(normalized['role']),
      ),
      'STATE_SNAPSHOT' => StateSnapshotEvent(
        rawJson: normalized,
        snapshot: normalizeObjectMap(normalized['snapshot']),
      ),
      'STATE_DELTA' => StateDeltaEvent(
        rawJson: normalized,
        delta: normalizeObjectList(normalized['delta']),
      ),
      'MESSAGES_SNAPSHOT' => MessagesSnapshotEvent(
        rawJson: normalized,
        messages: normalizeObjectList(normalized['messages'])
            .map((item) => AgUiMessage.fromJson(normalizeObjectMap(item)))
            .toList(growable: false),
      ),
      'ACTIVITY_SNAPSHOT' => ActivitySnapshotEvent(
        rawJson: normalized,
        messageId: normalizeString(normalized['messageId']) ?? '',
        activityType: normalizeString(normalized['activityType']) ?? '',
        content: normalizeObjectMap(normalized['content']),
        replace: normalized['replace'] is bool
            ? normalized['replace']! as bool
            : true,
      ),
      'ACTIVITY_DELTA' => ActivityDeltaEvent(
        rawJson: normalized,
        messageId: normalizeString(normalized['messageId']) ?? '',
        activityType: normalizeString(normalized['activityType']) ?? '',
        patch: normalizeObjectList(normalized['patch']),
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
      'RUN_STARTED' => RunStartedEvent(
        rawJson: normalized,
        threadId: normalizeString(normalized['threadId']) ?? '',
        runId: normalizeString(normalized['runId']) ?? '',
      ),
      'RUN_FINISHED' => RunFinishedEvent(
        rawJson: normalized,
        threadId: normalizeString(normalized['threadId']) ?? '',
        runId: normalizeString(normalized['runId']) ?? '',
      ),
      'RUN_ERROR' => RunErrorEvent(
        rawJson: normalized,
        message: normalizeString(normalized['message']) ?? '',
        code: normalizeString(normalized['code']),
      ),
      'STEP_STARTED' => StepStartedEvent(
        rawJson: normalized,
        stepName: normalizeString(normalized['stepName']) ?? '',
      ),
      'STEP_FINISHED' => StepFinishedEvent(
        rawJson: normalized,
        stepName: normalizeString(normalized['stepName']) ?? '',
      ),
      'THINKING_START' => ThinkingStartEvent(rawJson: normalized),
      'THINKING_TEXT_MESSAGE_START' => ThinkingTextMessageStartEvent(
        rawJson: normalized,
      ),
      'THINKING_TEXT_MESSAGE_CONTENT' => ThinkingTextMessageContentEvent(
        rawJson: normalized,
        delta: normalizeString(normalized['delta']) ?? '',
      ),
      'THINKING_TEXT_MESSAGE_END' => ThinkingTextMessageEndEvent(
        rawJson: normalized,
      ),
      'THINKING_END' => ThinkingEndEvent(rawJson: normalized),
      'REASONING_START' => ReasoningStartEvent(
        rawJson: normalized,
        messageId: normalizeString(normalized['messageId']) ?? '',
      ),
      'REASONING_MESSAGE_START' => ReasoningMessageStartEvent(
        rawJson: normalized,
        messageId: normalizeString(normalized['messageId']) ?? '',
      ),
      'REASONING_MESSAGE_CONTENT' => ReasoningMessageContentEvent(
        rawJson: normalized,
        messageId: normalizeString(normalized['messageId']) ?? '',
        delta: normalizeString(normalized['delta']) ?? '',
      ),
      'REASONING_MESSAGE_END' => ReasoningMessageEndEvent(
        rawJson: normalized,
        messageId: normalizeString(normalized['messageId']) ?? '',
      ),
      'REASONING_MESSAGE_CHUNK' => ReasoningMessageChunkEvent(
        rawJson: normalized,
        messageId: normalizeString(normalized['messageId']) ?? '',
        delta: normalizeString(normalized['delta']),
      ),
      'REASONING_END' => ReasoningEndEvent(
        rawJson: normalized,
        messageId: normalizeString(normalized['messageId']),
      ),
      'REASONING_ENCRYPTED_VALUE' => ReasoningEncryptedValueEvent(
        rawJson: normalized,
        entityId: normalizeString(normalized['entityId']) ?? '',
        subtype: normalizeString(normalized['subtype']) ?? '',
        encryptedValue: normalizeString(normalized['encryptedValue']) ?? '',
      ),
      _ => UnknownAgUiEvent(type: type, rawJson: normalized),
    };
  }
}

class TextMessageStartEvent extends AgUiEvent {
  const TextMessageStartEvent({
    required super.rawJson,
    required this.messageId,
    required this.role,
    required this.name,
  }) : super(type: 'TEXT_MESSAGE_START');

  final String messageId;
  final String role;
  final String? name;
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

class TextMessageEndEvent extends AgUiEvent {
  const TextMessageEndEvent({required super.rawJson, required this.messageId})
    : super(type: 'TEXT_MESSAGE_END');

  final String messageId;
}

class TextMessageChunkEvent extends AgUiEvent {
  const TextMessageChunkEvent({
    required super.rawJson,
    required this.messageId,
    required this.role,
    required this.delta,
    required this.name,
  }) : super(type: 'TEXT_MESSAGE_CHUNK');

  final String messageId;
  final String? role;
  final String? delta;
  final String? name;
}

class ToolCallStartEvent extends AgUiEvent {
  const ToolCallStartEvent({
    required super.rawJson,
    required this.toolCallId,
    required this.toolCallName,
    required this.parentMessageId,
  }) : super(type: 'TOOL_CALL_START');

  final String toolCallId;
  final String toolCallName;
  final String? parentMessageId;
}

class ToolCallArgsEvent extends AgUiEvent {
  const ToolCallArgsEvent({
    required super.rawJson,
    required this.toolCallId,
    required this.delta,
  }) : super(type: 'TOOL_CALL_ARGS');

  final String toolCallId;
  final String delta;
}

class ToolCallEndEvent extends AgUiEvent {
  const ToolCallEndEvent({required super.rawJson, required this.toolCallId})
    : super(type: 'TOOL_CALL_END');

  final String toolCallId;
}

class ToolCallChunkEvent extends AgUiEvent {
  const ToolCallChunkEvent({
    required super.rawJson,
    required this.toolCallId,
    required this.toolCallName,
    required this.parentMessageId,
    required this.delta,
  }) : super(type: 'TOOL_CALL_CHUNK');

  final String? toolCallId;
  final String? toolCallName;
  final String? parentMessageId;
  final String? delta;
}

class ToolCallResultEvent extends AgUiEvent {
  const ToolCallResultEvent({
    required super.rawJson,
    required this.messageId,
    required this.toolCallId,
    required this.content,
    required this.role,
  }) : super(type: 'TOOL_CALL_RESULT');

  final String messageId;
  final String toolCallId;
  final String content;
  final String? role;
}

class StateSnapshotEvent extends AgUiEvent {
  const StateSnapshotEvent({required super.rawJson, required this.snapshot})
    : super(type: 'STATE_SNAPSHOT');

  final Map<String, Object?> snapshot;
}

class StateDeltaEvent extends AgUiEvent {
  const StateDeltaEvent({required super.rawJson, required this.delta})
    : super(type: 'STATE_DELTA');

  final List<Object?> delta;
}

class MessagesSnapshotEvent extends AgUiEvent {
  const MessagesSnapshotEvent({required super.rawJson, required this.messages})
    : super(type: 'MESSAGES_SNAPSHOT');

  final List<AgUiMessage> messages;
}

class ActivitySnapshotEvent extends AgUiEvent {
  const ActivitySnapshotEvent({
    required super.rawJson,
    required this.messageId,
    required this.activityType,
    required this.content,
    required this.replace,
  }) : super(type: 'ACTIVITY_SNAPSHOT');

  final String messageId;
  final String activityType;
  final Map<String, Object?> content;
  final bool replace;
}

class ActivityDeltaEvent extends AgUiEvent {
  const ActivityDeltaEvent({
    required super.rawJson,
    required this.messageId,
    required this.activityType,
    required this.patch,
  }) : super(type: 'ACTIVITY_DELTA');

  final String messageId;
  final String activityType;
  final List<Object?> patch;
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

class RunStartedEvent extends AgUiEvent {
  const RunStartedEvent({
    required super.rawJson,
    required this.threadId,
    required this.runId,
  }) : super(type: 'RUN_STARTED');

  final String threadId;
  final String runId;
}

class RunFinishedEvent extends AgUiEvent {
  const RunFinishedEvent({
    required super.rawJson,
    required this.threadId,
    required this.runId,
  }) : super(type: 'RUN_FINISHED');

  final String threadId;
  final String runId;
}

class RunErrorEvent extends AgUiEvent {
  const RunErrorEvent({
    required super.rawJson,
    required this.message,
    required this.code,
  }) : super(type: 'RUN_ERROR');

  final String message;
  final String? code;
}

class StepStartedEvent extends AgUiEvent {
  const StepStartedEvent({required super.rawJson, required this.stepName})
    : super(type: 'STEP_STARTED');

  final String stepName;
}

class StepFinishedEvent extends AgUiEvent {
  const StepFinishedEvent({required super.rawJson, required this.stepName})
    : super(type: 'STEP_FINISHED');

  final String stepName;
}

class ThinkingStartEvent extends AgUiEvent {
  const ThinkingStartEvent({required super.rawJson})
    : super(type: 'THINKING_START');
}

class ThinkingTextMessageStartEvent extends AgUiEvent {
  const ThinkingTextMessageStartEvent({required super.rawJson})
    : super(type: 'THINKING_TEXT_MESSAGE_START');
}

class ThinkingTextMessageContentEvent extends AgUiEvent {
  const ThinkingTextMessageContentEvent({
    required super.rawJson,
    required this.delta,
  }) : super(type: 'THINKING_TEXT_MESSAGE_CONTENT');

  final String delta;
}

class ThinkingTextMessageEndEvent extends AgUiEvent {
  const ThinkingTextMessageEndEvent({required super.rawJson})
    : super(type: 'THINKING_TEXT_MESSAGE_END');
}

class ThinkingEndEvent extends AgUiEvent {
  const ThinkingEndEvent({required super.rawJson})
    : super(type: 'THINKING_END');
}

class ReasoningStartEvent extends AgUiEvent {
  const ReasoningStartEvent({required super.rawJson, required this.messageId})
    : super(type: 'REASONING_START');

  final String messageId;
}

class ReasoningMessageStartEvent extends AgUiEvent {
  const ReasoningMessageStartEvent({
    required super.rawJson,
    required this.messageId,
  }) : super(type: 'REASONING_MESSAGE_START');

  final String messageId;
}

class ReasoningMessageContentEvent extends AgUiEvent {
  const ReasoningMessageContentEvent({
    required super.rawJson,
    required this.messageId,
    required this.delta,
  }) : super(type: 'REASONING_MESSAGE_CONTENT');

  final String messageId;
  final String delta;
}

class ReasoningMessageEndEvent extends AgUiEvent {
  const ReasoningMessageEndEvent({
    required super.rawJson,
    required this.messageId,
  }) : super(type: 'REASONING_MESSAGE_END');

  final String messageId;
}

class ReasoningMessageChunkEvent extends AgUiEvent {
  const ReasoningMessageChunkEvent({
    required super.rawJson,
    required this.messageId,
    required this.delta,
  }) : super(type: 'REASONING_MESSAGE_CHUNK');

  final String messageId;
  final String? delta;
}

class ReasoningEndEvent extends AgUiEvent {
  const ReasoningEndEvent({required super.rawJson, required this.messageId})
    : super(type: 'REASONING_END');

  final String? messageId;
}

class ReasoningEncryptedValueEvent extends AgUiEvent {
  const ReasoningEncryptedValueEvent({
    required super.rawJson,
    required this.entityId,
    required this.subtype,
    required this.encryptedValue,
  }) : super(type: 'REASONING_ENCRYPTED_VALUE');

  final String entityId;
  final String subtype;
  final String encryptedValue;
}

class UnknownAgUiEvent extends AgUiEvent {
  const UnknownAgUiEvent({required super.type, required super.rawJson});
}
