import 'dart:convert';

import '../agui/protocol/agui_message.dart';
import '../agui/session/thread_session.dart';
import '../agui/transport/agent_transport.dart';
import '../features/tools/application/frontend_tool_executor.dart';
import '../features/tools/application/frontend_tool_registry.dart';
import '../features/tools/domain/frontend_tool.dart';
import 'copilot_action_response_coordinator.dart';

typedef CopilotToolMessageIdFactory = String Function(ToolCallViewModel call);

class CopilotToolRunLoopResult {
  const CopilotToolRunLoopResult({
    required this.session,
    required this.followUpMessages,
  });

  final ThreadSession session;
  final List<AgUiMessage> followUpMessages;

  bool get hasFollowUpMessages => followUpMessages.isNotEmpty;
}

class CopilotToolRunLoop {
  CopilotToolRunLoop({
    required FrontendToolRegistry registry,
    CopilotActionResponseCoordinator? responseCoordinator,
    CopilotToolMessageIdFactory? messageIdFactory,
  }) : _registry = registry,
       _responseCoordinator = responseCoordinator,
       _executor = FrontendToolExecutor(registry: registry),
       _messageIdFactory = messageIdFactory ?? ((call) => 'tool-${call.id}');

  final FrontendToolRegistry _registry;
  final CopilotActionResponseCoordinator? _responseCoordinator;
  final FrontendToolExecutor _executor;
  final CopilotToolMessageIdFactory _messageIdFactory;
  final Set<String> _completedToolCallIds = <String>{};

  Future<CopilotToolRunLoopResult> drainEndedToolCalls({
    required ThreadSession session,
    required FrontendToolAvailabilityContext availabilityContext,
    FrontendToolExecutionContext executionContext =
        const FrontendToolExecutionContext(),
    AgUiTransportCancellationToken? cancelToken,
  }) async {
    var nextSession = session;
    final followUpMessages = <AgUiMessage>[];

    for (final call in session.toolCalls.values) {
      if (!_shouldHandle(call)) {
        continue;
      }

      _completedToolCallIds.add(call.id);
      if (cancelToken?.isCancelled ?? false) {
        nextSession = _markResult(nextSession, call, <String, Object?>{
          'error': <String, Object?>{
            'code': 'tool_execution_cancelled',
            'message': 'Tool execution was cancelled.',
          },
        });
        continue;
      }

      final tool = _registry.toolNamed(call.name);
      if (tool == null) {
        final message = _errorMessage(
          call,
          code: 'missing_tool',
          message: 'Tool "${call.name}" is not registered.',
        );
        nextSession = _markResult(nextSession, call, _decodePayload(message));
        followUpMessages.add(message);
        continue;
      }

      if (!tool.canExecuteLocally) {
        nextSession = _markResult(nextSession, call, <String, Object?>{
          'status': 'remote_only',
          'message': 'Tool "${call.name}" is remote-only.',
        });
        continue;
      }

      final availability = tool.availability(availabilityContext);
      if (!availability.isAvailable) {
        final message = _errorMessage(
          call,
          code: switch (availability.status) {
            FrontendToolAvailabilityStatus.missingPermission =>
              'missing_permission',
            FrontendToolAvailabilityStatus.disabledByCapability =>
              'disabled_by_capability',
            FrontendToolAvailabilityStatus.available => 'unavailable',
          },
          message: availability.reason ?? 'Tool "${call.name}" is unavailable.',
        );
        nextSession = _markResult(nextSession, call, _decodePayload(message));
        followUpMessages.add(message);
        continue;
      }

      if (tool.waitsForUserResponse) {
        final coordinator = _responseCoordinator;
        if (coordinator == null) {
          final message = _errorMessage(
            call,
            code: 'user_response_unavailable',
            message: 'Tool "${call.name}" requires a user response.',
          );
          nextSession = _markResult(nextSession, call, _decodePayload(message));
          followUpMessages.add(message);
          continue;
        }

        nextSession = _markResult(nextSession, call, <String, Object?>{
          'status': 'waiting_for_response',
          'arguments': call.arguments,
        });
        final response = await coordinator.waitForResponse(call);
        final message = _toolMessage(call, response);
        nextSession = _markResult(nextSession, call, response);
        if (tool.shouldFollowUp) {
          followUpMessages.add(message);
        }
        continue;
      }

      final message = await _executor.execute(
        call,
        context: executionContext,
        cancelToken: cancelToken,
        messageId: _messageIdFactory(call),
      );
      nextSession = _markResult(nextSession, call, _decodePayload(message));
      if (tool.shouldFollowUp) {
        followUpMessages.add(message);
      }
    }

    return CopilotToolRunLoopResult(
      session: nextSession,
      followUpMessages: List<AgUiMessage>.unmodifiable(followUpMessages),
    );
  }

  bool _shouldHandle(ToolCallViewModel call) {
    return call.stage == ToolCallStage.ended &&
        !_completedToolCallIds.contains(call.id);
  }

  AgUiMessage _errorMessage(
    ToolCallViewModel call, {
    required String code,
    required String message,
  }) {
    return AgUiMessage(
      id: _messageIdFactory(call),
      role: AgUiMessageRole.tool,
      content: <AgUiMessageContentPart>[
        AgUiTextContentPart(
          text: jsonEncode(<String, Object?>{
            'error': <String, Object?>{'code': code, 'message': message},
          }),
        ),
      ],
      metadata: <String, Object?>{'toolCallId': call.id, 'error': 'true'},
    );
  }

  AgUiMessage _toolMessage(
    ToolCallViewModel call,
    Map<String, Object?> payload,
  ) {
    final isError = payload['error'] != null;
    return AgUiMessage(
      id: _messageIdFactory(call),
      role: AgUiMessageRole.tool,
      content: <AgUiMessageContentPart>[
        AgUiTextContentPart(text: jsonEncode(payload)),
      ],
      metadata: <String, Object?>{
        'toolCallId': call.id,
        if (isError) 'error': 'true',
      },
    );
  }

  ThreadSession _markResult(
    ThreadSession session,
    ToolCallViewModel call,
    Object? result,
  ) {
    return session.copyWith(
      toolCalls: <String, ToolCallViewModel>{
        ...session.toolCalls,
        call.id: call.copyWith(stage: ToolCallStage.result, result: result),
      },
    );
  }

  Object? _decodePayload(AgUiMessage message) {
    if (message.content.isEmpty) {
      return null;
    }
    final first = message.content.first;
    if (first is! AgUiTextContentPart) {
      return first.toJson();
    }
    try {
      return jsonDecode(first.text);
    } on FormatException {
      return first.text;
    }
  }
}
