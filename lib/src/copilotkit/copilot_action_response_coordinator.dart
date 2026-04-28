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
  final Object? response;

  CopilotActionResponseRequest copyWith({
    CopilotActionResponseStatus? status,
    Object? response = _unset,
  }) {
    return CopilotActionResponseRequest(
      toolCallId: toolCallId,
      toolName: toolName,
      arguments: arguments,
      status: status ?? this.status,
      response: identical(response, _unset) ? this.response : response,
    );
  }
}

class CopilotActionResponseCoordinator {
  final Map<String, CopilotActionResponseRequest> _requests =
      <String, CopilotActionResponseRequest>{};
  final Map<String, Completer<Object?>> _completers =
      <String, Completer<Object?>>{};
  final StreamController<List<CopilotActionResponseRequest>>
  _requestsController =
      StreamController<List<CopilotActionResponseRequest>>.broadcast();

  Stream<List<CopilotActionResponseRequest>> get requestsStream {
    return _requestsController.stream;
  }

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

  Future<Object?> waitForResponse(ToolCallViewModel call) {
    final existing = _completers[call.id];
    if (existing != null) {
      return existing.future;
    }

    final completer = Completer<Object?>();
    _completers[call.id] = completer;
    _requests[call.id] = CopilotActionResponseRequest(
      toolCallId: call.id,
      toolName: call.name,
      arguments: Map<String, Object?>.unmodifiable(call.arguments),
      status: CopilotActionResponseStatus.waiting,
    );
    _publishRequests();
    return completer.future;
  }

  bool complete(String toolCallId, Object? response) {
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
              response: _freezeResponse(response),
            );
    completer.complete(_freezeResponse(response));
    _publishRequests();
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
    _publishRequests();
    return true;
  }

  void cancelAll([String message = 'Action response was cancelled.']) {
    for (final toolCallId in _completers.keys.toList(growable: false)) {
      reject(toolCallId, message);
    }
  }

  void dispose() {
    _requestsController.close();
  }

  Object? _freezeResponse(Object? response) {
    if (response is Map<String, Object?>) {
      return Map<String, Object?>.unmodifiable(response);
    }
    if (response is List<Object?>) {
      return List<Object?>.unmodifiable(response);
    }
    return response;
  }

  void _publishRequests() {
    if (_requestsController.isClosed) {
      return;
    }
    _requestsController.add(
      List<CopilotActionResponseRequest>.unmodifiable(pendingRequests),
    );
  }
}

const _unset = Object();
