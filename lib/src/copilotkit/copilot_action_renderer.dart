import 'package:flutter/widgets.dart';

import '../agui/session/thread_session.dart';

enum CopilotActionRenderStatus {
  streamingArguments,
  ready,
  running,
  waitingForResponse,
  succeeded,
  failed,
  remote,
}

class CopilotActionRenderContext {
  const CopilotActionRenderContext({
    required this.toolCallId,
    required this.toolName,
    required this.arguments,
    required this.status,
    this.result,
    this.submitResponse,
    this.reject,
  });

  factory CopilotActionRenderContext.fromToolCall(
    ToolCallViewModel call, {
    void Function(Map<String, Object?> response)? submitResponse,
    void Function([String message])? reject,
  }) {
    return CopilotActionRenderContext(
      toolCallId: call.id,
      toolName: call.name,
      arguments: call.arguments,
      status: _statusFromCall(call),
      result: call.result,
      submitResponse: submitResponse,
      reject: reject,
    );
  }

  final String toolCallId;
  final String toolName;
  final Map<String, Object?> arguments;
  final CopilotActionRenderStatus status;
  final Object? result;
  final void Function(Map<String, Object?> response)? submitResponse;
  final void Function([String message])? reject;

  bool get canRespond => submitResponse != null;
}

typedef CopilotActionWidgetBuilder =
    Widget Function(
      BuildContext context,
      CopilotActionRenderContext contextData,
    );

class CopilotActionRenderer {
  const CopilotActionRenderer({required this.id, required this.builder});

  final String id;
  final CopilotActionWidgetBuilder builder;

  Widget build(BuildContext context, CopilotActionRenderContext contextData) {
    return builder(context, contextData);
  }
}

class CopilotActionRendererRegistry {
  const CopilotActionRendererRegistry({
    required this.defaultRenderer,
    this.renderers = const <String, CopilotActionRenderer>{},
  });

  final CopilotActionRenderer defaultRenderer;
  final Map<String, CopilotActionRenderer> renderers;

  CopilotActionRenderer resolve(String toolName) {
    return renderers[toolName] ?? defaultRenderer;
  }

  Widget build(
    BuildContext context,
    ToolCallViewModel call, {
    void Function(Map<String, Object?> response)? submitResponse,
    void Function([String message])? reject,
  }) {
    final contextData = CopilotActionRenderContext.fromToolCall(
      call,
      submitResponse: submitResponse,
      reject: reject,
    );
    return resolve(call.name).build(context, contextData);
  }
}

CopilotActionRenderStatus _statusFromCall(ToolCallViewModel call) {
  return switch (call.stage) {
    ToolCallStage.idle ||
    ToolCallStage.started => CopilotActionRenderStatus.ready,
    ToolCallStage.arguments => CopilotActionRenderStatus.streamingArguments,
    ToolCallStage.ended => CopilotActionRenderStatus.running,
    ToolCallStage.result => _resultStatus(call.result),
  };
}

CopilotActionRenderStatus _resultStatus(Object? result) {
  if (result is Map && result['error'] != null) {
    return CopilotActionRenderStatus.failed;
  }
  if (result is Map && result['status'] == 'remote_only') {
    return CopilotActionRenderStatus.remote;
  }
  if (result is Map && result['status'] == 'waiting_for_response') {
    return CopilotActionRenderStatus.waitingForResponse;
  }
  return CopilotActionRenderStatus.succeeded;
}
