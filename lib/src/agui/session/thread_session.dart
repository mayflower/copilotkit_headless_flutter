import '../protocol/agui_event_envelope.dart';
import '../protocol/agui_message.dart';
import 'shared_state_document.dart';

enum RunStatus { idle, starting, running, interrupted, completed, failed }

enum ConnectionStatus { online, reconnecting, offline, degraded }

enum ToolCallStage { idle, started, arguments, ended, result }

enum ReasoningStage { started, streaming, ended }

class UiMessage {
  const UiMessage({
    required this.id,
    required this.role,
    required this.text,
    this.isStreaming = false,
  });

  final String id;
  final AgUiMessageRole role;
  final String text;
  final bool isStreaming;

  UiMessage copyWith({
    String? id,
    AgUiMessageRole? role,
    String? text,
    bool? isStreaming,
  }) {
    return UiMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

class ToolCallViewModel {
  const ToolCallViewModel({
    required this.id,
    required this.name,
    this.stage = ToolCallStage.idle,
    this.arguments = const <String, Object?>{},
    this.argumentsBuffer = '',
    this.result,
  });

  final String id;
  final String name;
  final ToolCallStage stage;
  final Map<String, Object?> arguments;
  final String argumentsBuffer;
  final Object? result;

  ToolCallViewModel copyWith({
    String? id,
    String? name,
    ToolCallStage? stage,
    Map<String, Object?>? arguments,
    String? argumentsBuffer,
    Object? result = _unset,
  }) {
    return ToolCallViewModel(
      id: id ?? this.id,
      name: name ?? this.name,
      stage: stage ?? this.stage,
      arguments: arguments ?? this.arguments,
      argumentsBuffer: argumentsBuffer ?? this.argumentsBuffer,
      result: identical(result, _unset) ? this.result : result,
    );
  }
}

class ReasoningViewModel {
  const ReasoningViewModel({
    required this.id,
    this.stage = ReasoningStage.started,
    this.text = '',
    this.encryptedValues = const <String, String>{},
  });

  final String id;
  final ReasoningStage stage;
  final String text;
  final Map<String, String> encryptedValues;

  ReasoningViewModel copyWith({
    String? id,
    ReasoningStage? stage,
    String? text,
    Map<String, String>? encryptedValues,
  }) {
    return ReasoningViewModel(
      id: id ?? this.id,
      stage: stage ?? this.stage,
      text: text ?? this.text,
      encryptedValues: encryptedValues ?? this.encryptedValues,
    );
  }
}

class ActivityViewModel {
  const ActivityViewModel({
    required this.id,
    required this.label,
    required this.status,
    this.summary,
    this.details = const <String, Object?>{},
  });

  final String id;
  final String label;
  final String status;
  final String? summary;
  final Map<String, Object?> details;

  ActivityViewModel copyWith({
    String? id,
    String? label,
    String? status,
    Object? summary = _unset,
    Map<String, Object?>? details,
  }) {
    return ActivityViewModel(
      id: id ?? this.id,
      label: label ?? this.label,
      status: status ?? this.status,
      summary: identical(summary, _unset) ? this.summary : summary as String?,
      details: details ?? this.details,
    );
  }
}

class DebugEventViewModel {
  const DebugEventViewModel({
    required this.type,
    required this.rawPayload,
    required this.receivedAt,
    this.payload = const <String, Object?>{},
    this.decodeErrorMessage,
  });

  final String type;
  final String rawPayload;
  final DateTime receivedAt;
  final Map<String, Object?> payload;
  final String? decodeErrorMessage;
}

class ThreadSession {
  const ThreadSession({
    required this.threadId,
    this.activeRunId,
    this.parentRunId,
    required this.runStatus,
    required this.connectionStatus,
    required this.messages,
    required this.toolCalls,
    required this.activities,
    required this.reasoning,
    required this.sharedState,
    required this.debugEvents,
    required this.eventLog,
    required this.requiresSharedStateRecovery,
    this.lastEventAt,
    this.lastErrorMessage,
    this.sharedStateFailureReason,
    this.lastSharedStateRecoveredAt,
  });

  factory ThreadSession.initial(
    String threadId, {
    ConnectionStatus connectionStatus = ConnectionStatus.online,
  }) {
    return ThreadSession(
      threadId: threadId,
      runStatus: RunStatus.idle,
      connectionStatus: connectionStatus,
      messages: const <UiMessage>[],
      toolCalls: const <String, ToolCallViewModel>{},
      activities: const <String, ActivityViewModel>{},
      reasoning: const <String, ReasoningViewModel>{},
      sharedState: SharedStateDocument.empty(),
      debugEvents: const <DebugEventViewModel>[],
      eventLog: const <AgUiEventEnvelope>[],
      requiresSharedStateRecovery: false,
    );
  }

  final String threadId;
  final String? activeRunId;
  final String? parentRunId;
  final RunStatus runStatus;
  final ConnectionStatus connectionStatus;
  final List<UiMessage> messages;
  final Map<String, ToolCallViewModel> toolCalls;
  final Map<String, ActivityViewModel> activities;
  final Map<String, ReasoningViewModel> reasoning;
  final SharedStateDocument sharedState;
  final List<DebugEventViewModel> debugEvents;
  final List<AgUiEventEnvelope> eventLog;
  final bool requiresSharedStateRecovery;
  final DateTime? lastEventAt;
  final String? lastErrorMessage;
  final String? sharedStateFailureReason;
  final DateTime? lastSharedStateRecoveredAt;

  ThreadSession copyWith({
    Object? activeRunId = _unset,
    Object? parentRunId = _unset,
    RunStatus? runStatus,
    ConnectionStatus? connectionStatus,
    List<UiMessage>? messages,
    Map<String, ToolCallViewModel>? toolCalls,
    Map<String, ActivityViewModel>? activities,
    Map<String, ReasoningViewModel>? reasoning,
    SharedStateDocument? sharedState,
    List<DebugEventViewModel>? debugEvents,
    List<AgUiEventEnvelope>? eventLog,
    bool? requiresSharedStateRecovery,
    Object? lastEventAt = _unset,
    Object? lastErrorMessage = _unset,
    Object? sharedStateFailureReason = _unset,
    Object? lastSharedStateRecoveredAt = _unset,
  }) {
    return ThreadSession(
      threadId: threadId,
      activeRunId: identical(activeRunId, _unset)
          ? this.activeRunId
          : activeRunId as String?,
      parentRunId: identical(parentRunId, _unset)
          ? this.parentRunId
          : parentRunId as String?,
      runStatus: runStatus ?? this.runStatus,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      messages: messages ?? this.messages,
      toolCalls: toolCalls ?? this.toolCalls,
      activities: activities ?? this.activities,
      reasoning: reasoning ?? this.reasoning,
      sharedState: sharedState ?? this.sharedState,
      debugEvents: debugEvents ?? this.debugEvents,
      eventLog: eventLog ?? this.eventLog,
      requiresSharedStateRecovery:
          requiresSharedStateRecovery ?? this.requiresSharedStateRecovery,
      lastEventAt: identical(lastEventAt, _unset)
          ? this.lastEventAt
          : lastEventAt as DateTime?,
      lastErrorMessage: identical(lastErrorMessage, _unset)
          ? this.lastErrorMessage
          : lastErrorMessage as String?,
      sharedStateFailureReason: identical(sharedStateFailureReason, _unset)
          ? this.sharedStateFailureReason
          : sharedStateFailureReason as String?,
      lastSharedStateRecoveredAt: identical(lastSharedStateRecoveredAt, _unset)
          ? this.lastSharedStateRecoveredAt
          : lastSharedStateRecoveredAt as DateTime?,
    );
  }
}

const _unset = Object();
