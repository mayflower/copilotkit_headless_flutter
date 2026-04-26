import 'dart:async';

import '../agui/session/thread_session.dart';

enum CopilotActionResponseStatus { waiting, completed, rejected }

class CopilotActionResponseRequest {
  const CopilotActionResponseRequest({
    required this.toolCallId,
    required this.toolName,
    required this.arguments,
    required this.status,
    this.response,
  });

  final String toolCallId;
  final String toolName;
  final Map<String, Object?> arguments;
  final CopilotActionResponseStatus status;
  final Map<String, Object?>? response;

  CopilotActionResponseRequest copyWith({
    CopilotActionResponseStatus? status,
    Object? response = _unset,
  }) {
    return CopilotActionResponseRequest(
      toolCallId: toolCallId,
      toolName: toolName,
      arguments: arguments,
      status: status ?? this.status,
      response: identical(response, _unset)
          ? this.response
          : response as Map<String, Object?>?,
    );
  }
}

class CopilotActionResponseCoordinator {
  final Map<String, CopilotActionResponseRequest> _requests =
      <String, CopilotActionResponseRequest>{};
  final Map<String, Completer<Map<String, Object?>>> _completers =
      <String, Completer<Map<String, Object?>>>{};

  List<CopilotActionResponseRequest> get pendingRequests {
    return _requests.values
        .where(
          (request) => request.status == CopilotActionResponseStatus.waiting,
        )
        .toList(growable: false);
  }

  CopilotActionResponseRequest? requestFor(String toolCallId) {
    return _requests[toolCallId];
  }

  Future<Map<String, Object?>> waitForResponse(ToolCallViewModel call) {
    final existing = _completers[call.id];
    if (existing != null) {
      return existing.future;
    }

    final completer = Completer<Map<String, Object?>>();
    _completers[call.id] = completer;
    _requests[call.id] = CopilotActionResponseRequest(
      toolCallId: call.id,
      toolName: call.name,
      arguments: Map<String, Object?>.unmodifiable(call.arguments),
      status: CopilotActionResponseStatus.waiting,
    );
    return completer.future;
  }

  bool complete(String toolCallId, Map<String, Object?> response) {
    final completer = _completers.remove(toolCallId);
    if (completer == null || completer.isCompleted) {
      return false;
    }
    _requests[toolCallId] =
        (_requests[toolCallId] ??
                CopilotActionResponseRequest(
                  toolCallId: toolCallId,
                  toolName: 'tool',
                  arguments: const <String, Object?>{},
                  status: CopilotActionResponseStatus.waiting,
                ))
            .copyWith(
              status: CopilotActionResponseStatus.completed,
              response: Map<String, Object?>.unmodifiable(response),
            );
    completer.complete(Map<String, Object?>.unmodifiable(response));
    return true;
  }

  bool reject(
    String toolCallId, [
    String message = 'User rejected the action.',
  ]) {
    final completer = _completers.remove(toolCallId);
    if (completer == null || completer.isCompleted) {
      return false;
    }
    final response = <String, Object?>{
      'error': <String, Object?>{'code': 'user_rejected', 'message': message},
    };
    _requests[toolCallId] =
        (_requests[toolCallId] ??
                CopilotActionResponseRequest(
                  toolCallId: toolCallId,
                  toolName: 'tool',
                  arguments: const <String, Object?>{},
                  status: CopilotActionResponseStatus.waiting,
                ))
            .copyWith(
              status: CopilotActionResponseStatus.rejected,
              response: response,
            );
    completer.complete(response);
    return true;
  }
}

const _unset = Object();
