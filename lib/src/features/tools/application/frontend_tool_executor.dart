import 'dart:convert';

import '../../../agui/protocol/agui_message.dart';
import '../../../agui/session/thread_session.dart';
import '../../../agui/transport/agent_transport.dart';
import '../domain/frontend_tool.dart';
import 'frontend_tool_registry.dart';

class FrontendToolExecutor {
  const FrontendToolExecutor({required FrontendToolRegistry registry})
    : _registry = registry;

  final FrontendToolRegistry _registry;

  Future<AgUiMessage> execute(
    ToolCallViewModel toolCall, {
    required FrontendToolExecutionContext context,
    AgUiTransportCancellationToken? cancelToken,
    String? messageId,
  }) async {
    final tool = _registry.toolNamed(toolCall.name);
    if (tool == null) {
      return _toolMessage(
        messageId: messageId,
        toolCallId: toolCall.id,
        payload: <String, Object?>{
          'error': <String, Object?>{
            'code': 'missing_tool',
            'message': 'Tool "${toolCall.name}" is not registered.',
          },
        },
        isError: true,
      );
    }

    if (!tool.canExecuteLocally) {
      return _toolMessage(
        messageId: messageId,
        toolCallId: toolCall.id,
        payload: <String, Object?>{
          'error': <String, Object?>{
            'code': 'remote_only_tool',
            'message': 'Tool "${toolCall.name}" is remote-only.',
          },
        },
        isError: true,
      );
    }

    try {
      final result = await tool.execute(
        toolCall.arguments,
        context: context,
        cancelToken: cancelToken,
      );
      return _toolMessage(
        messageId: messageId,
        toolCallId: toolCall.id,
        payload: result.payload,
      );
    } catch (error) {
      return _toolMessage(
        messageId: messageId,
        toolCallId: toolCall.id,
        payload: <String, Object?>{
          'error': <String, Object?>{
            'code': 'tool_execution_failed',
            'message': error.toString(),
          },
        },
        isError: true,
      );
    }
  }
}

AgUiMessage _toolMessage({
  required String? messageId,
  required String toolCallId,
  required Map<String, Object?> payload,
  bool isError = false,
}) {
  return AgUiMessage(
    id: messageId ?? 'tool-$toolCallId',
    role: AgUiMessageRole.tool,
    content: <AgUiMessageContentPart>[
      AgUiTextContentPart(text: jsonEncode(payload)),
    ],
    metadata: <String, Object?>{
      'toolCallId': toolCallId,
      if (isError) 'error': true,
    },
  );
}
