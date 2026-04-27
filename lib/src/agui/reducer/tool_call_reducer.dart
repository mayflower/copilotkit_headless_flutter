import 'dart:convert';

import '../protocol/agui_event_envelope.dart';
import '../protocol/agui_json.dart';
import '../session/thread_session.dart';
import 'agui_reducer.dart';

class ToolCallReducer implements AgUiReducer {
  const ToolCallReducer();

  @override
  ThreadSession reduce(ThreadSession current, AgUiEventEnvelope event) {
    final toolCallId = event.stringValue('toolCallId');
    if (toolCallId == null) {
      return current;
    }

    final existing = current.toolCalls[toolCallId];
    final name = event.stringValue('toolCallName') ?? existing?.name ?? 'tool';

    final nextToolCall = switch (event.type) {
      'TOOL_CALL_CHUNK' => _reduceChunk(existing, event, toolCallId, name),
      'TOOL_CALL_START' => ToolCallViewModel(
        id: toolCallId,
        name: name,
        stage: ToolCallStage.started,
      ),
      'TOOL_CALL_ARGS' => _reduceArgs(existing, event, toolCallId, name),
      'TOOL_CALL_END' =>
        (existing ?? ToolCallViewModel(id: toolCallId, name: name)).copyWith(
          stage: ToolCallStage.ended,
          arguments: _finalArguments(existing),
        ),
      'TOOL_CALL_RESULT' =>
        (existing ?? ToolCallViewModel(id: toolCallId, name: name)).copyWith(
          stage: ToolCallStage.result,
          result:
              event.payload['result'] ??
              event.payload['content'] ??
              event.payload['value'],
        ),
      _ => null,
    };

    if (nextToolCall == null) {
      return current;
    }

    return current.copyWith(
      toolCalls: <String, ToolCallViewModel>{
        ...current.toolCalls,
        toolCallId: nextToolCall,
      },
    );
  }
}

ToolCallViewModel _reduceChunk(
  ToolCallViewModel? existing,
  AgUiEventEnvelope event,
  String toolCallId,
  String name,
) {
  final base = existing ?? ToolCallViewModel(id: toolCallId, name: name);
  final delta = _readRawString(event.payload['delta']);
  if (delta == null) {
    return base.copyWith(stage: ToolCallStage.arguments);
  }

  return base.copyWith(
    stage: ToolCallStage.arguments,
    argumentsBuffer: '${base.argumentsBuffer}$delta',
  );
}

ToolCallViewModel _reduceArgs(
  ToolCallViewModel? existing,
  AgUiEventEnvelope event,
  String toolCallId,
  String name,
) {
  final base = existing ?? ToolCallViewModel(id: toolCallId, name: name);
  final args = event.objectValue('args') ?? event.objectValue('arguments');
  if (args != null) {
    return base.copyWith(stage: ToolCallStage.arguments, arguments: args);
  }

  final delta =
      _readRawString(event.payload['delta']) ??
      _readRawString(event.payload['content']);
  if (delta == null) {
    return base.copyWith(stage: ToolCallStage.arguments);
  }

  return base.copyWith(
    stage: ToolCallStage.arguments,
    argumentsBuffer: '${base.argumentsBuffer}$delta',
  );
}

Map<String, Object?> _finalArguments(ToolCallViewModel? existing) {
  if (existing == null || existing.argumentsBuffer.trim().isEmpty) {
    return existing?.arguments ?? const <String, Object?>{};
  }

  try {
    return normalizeObjectMap(jsonDecode(existing.argumentsBuffer));
  } on FormatException {
    return existing.arguments;
  }
}

String? _readRawString(Object? value) {
  if (value is! String) {
    return null;
  }
  return value.isEmpty ? null : value;
}
