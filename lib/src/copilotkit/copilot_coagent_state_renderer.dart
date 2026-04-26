import 'package:flutter/widgets.dart';

import 'copilot_coagent_state.dart';

enum CopilotCoAgentStateRenderStatus {
  idle,
  running,
  waiting,
  completed,
  error,
}

class CopilotCoAgentStateRenderContext {
  const CopilotCoAgentStateRenderContext({
    required this.scope,
    required this.data,
    this.status = CopilotCoAgentStateRenderStatus.idle,
  });

  final CopilotCoAgentScope scope;
  final Map<String, Object?> data;
  final CopilotCoAgentStateRenderStatus status;
}

typedef CopilotCoAgentStateWidgetBuilder =
    Widget Function(
      BuildContext context,
      CopilotCoAgentStateRenderContext contextData,
    );

class CopilotCoAgentStateRenderer {
  const CopilotCoAgentStateRenderer({required this.id, required this.builder});

  final String id;
  final CopilotCoAgentStateWidgetBuilder builder;

  Widget build(
    BuildContext context,
    CopilotCoAgentStateRenderContext contextData,
  ) {
    return builder(context, contextData);
  }
}

class CopilotCoAgentStateRendererRegistry {
  const CopilotCoAgentStateRendererRegistry({
    required this.defaultRenderer,
    this.renderers = const <String, CopilotCoAgentStateRenderer>{},
  });

  final CopilotCoAgentStateRenderer defaultRenderer;
  final Map<String, CopilotCoAgentStateRenderer> renderers;

  CopilotCoAgentStateRenderer resolve(CopilotCoAgentScope scope) {
    return renderers[_scopeKey(scope)] ??
        renderers[scope.agentId] ??
        defaultRenderer;
  }

  Widget build(
    BuildContext context, {
    required CopilotCoAgentScope scope,
    required Map<String, Object?> data,
    CopilotCoAgentStateRenderStatus status =
        CopilotCoAgentStateRenderStatus.idle,
  }) {
    return resolve(scope).build(
      context,
      CopilotCoAgentStateRenderContext(
        scope: scope,
        data: data,
        status: status,
      ),
    );
  }
}

String _scopeKey(CopilotCoAgentScope scope) {
  final nodeId = scope.nodeId;
  return nodeId == null ? scope.agentId : '${scope.agentId}/$nodeId';
}
