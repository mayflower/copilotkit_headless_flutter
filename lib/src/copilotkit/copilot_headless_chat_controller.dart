import 'dart:async';

import 'package:flutter/foundation.dart';

import '../agui/capabilities/capability_service.dart';
import '../agui/protocol/agui_message.dart';
import '../agui/protocol/run_agent_input.dart';
import '../agui/session/thread_session.dart';
import '../agui/session/thread_session_controller.dart';
import '../agui/transport/agent_transport.dart';
import '../features/tools/application/frontend_tool_registry.dart';
import '../features/tools/domain/frontend_tool.dart';
import 'copilot_action.dart';
import 'copilot_action_response_coordinator.dart';
import 'copilot_readable_registry.dart';
import 'copilot_runtime_config.dart';
import 'copilot_tool_run_loop.dart';

typedef CopilotIdFactory = String Function();

class CopilotHeadlessChatSnapshot {
  const CopilotHeadlessChatSnapshot({
    required this.session,
    required this.messages,
    required this.inProgress,
  });

  final ThreadSession session;
  final List<AgUiMessage> messages;
  final bool inProgress;

  List<UiMessage> get visibleMessages => session.messages;
}

class CopilotHeadlessChatController extends ChangeNotifier {
  CopilotHeadlessChatController({
    required AgentTransport transport,
    required CopilotRuntimeConfig runtime,
    ThreadSessionController? sessionController,
    CopilotReadableRegistry? readableRegistry,
    FrontendToolRegistry? frontendToolRegistry,
    CopilotActionRegistry? actionRegistry,
    CopilotToolRunLoop? toolRunLoop,
    CopilotActionResponseCoordinator? responseCoordinator,
    CapabilityService capabilityService = const CapabilityService(),
    CopilotIdFactory? idFactory,
  }) : _transport = transport,
       _runtime = runtime,
       _sessionController = sessionController ?? ThreadSessionController(),
       _readableRegistry = readableRegistry ?? CopilotReadableRegistry(),
       _frontendToolRegistry =
           frontendToolRegistry ??
           actionRegistry?.toFrontendToolRegistry() ??
           FrontendToolRegistry(tools: const <FrontendTool>[]),
       _toolRunLoop =
           toolRunLoop ??
           CopilotToolRunLoop(
             registry:
                 frontendToolRegistry ??
                 actionRegistry?.toFrontendToolRegistry() ??
                 FrontendToolRegistry(tools: const <FrontendTool>[]),
             responseCoordinator: responseCoordinator,
           ),
       _capabilityService = capabilityService,
       _idFactory = idFactory ?? _timestampId,
       _session = ThreadSession.initial(runtime.threadId);

  final AgentTransport _transport;
  final ThreadSessionController _sessionController;
  final CopilotReadableRegistry _readableRegistry;
  final FrontendToolRegistry _frontendToolRegistry;
  final CopilotToolRunLoop _toolRunLoop;
  final CapabilityService _capabilityService;
  final CopilotIdFactory _idFactory;

  CopilotRuntimeConfig _runtime;
  ThreadSession _session;
  List<AgUiMessage> _messages = const <AgUiMessage>[];
  AgUiTransportCancellationToken? _cancelToken;
  bool _inProgress = false;

  CopilotRuntimeConfig get runtime => _runtime;

  ThreadSession get session => _session;

  List<AgUiMessage> get messages => List<AgUiMessage>.unmodifiable(_messages);

  List<UiMessage> get visibleMessages => _session.messages;

  bool get inProgress => _inProgress;

  CopilotHeadlessChatSnapshot get snapshot {
    return CopilotHeadlessChatSnapshot(
      session: _session,
      messages: messages,
      inProgress: _inProgress,
    );
  }

  void configure(CopilotRuntimeConfig runtime) {
    final threadChanged = runtime.threadId != _runtime.threadId;
    _runtime = runtime;
    if (threadChanged) {
      reset(threadId: runtime.threadId);
      return;
    }
    notifyListeners();
  }

  void setMessages(List<AgUiMessage> messages) {
    _messages = List<AgUiMessage>.unmodifiable(messages);
    _session = _session.copyWith(messages: _toUiMessages(_messages));
    notifyListeners();
  }

  void deleteMessage(String messageId) {
    _messages = _messages
        .where((message) => message.id != messageId)
        .toList(growable: false);
    _session = _session.copyWith(
      messages: _session.messages
          .where((message) => message.id != messageId)
          .toList(growable: false),
    );
    notifyListeners();
  }

  void reset({String? threadId}) {
    final nextThreadId = threadId ?? _runtime.threadId;
    _cancelToken?.cancel();
    _cancelToken = null;
    _inProgress = false;
    _messages = const <AgUiMessage>[];
    _session = ThreadSession.initial(nextThreadId);
    _runtime = _runtime.copyWith(threadId: nextThreadId);
    notifyListeners();
  }

  Future<void> submitUserMessage(
    String text, {
    String? messageId,
    String? runId,
    String? parentRunId,
    Map<String, Object?> state = const <String, Object?>{},
    List<AgUiContextEntry> context = const <AgUiContextEntry>[],
    List<AgUiToolDefinition>? tools,
    Map<String, Object?> forwardedProps = const <String, Object?>{},
  }) {
    final id = messageId ?? _idFactory();
    return appendMessage(
      AgUiMessage(
        id: id,
        role: AgUiMessageRole.user,
        content: <AgUiMessageContentPart>[AgUiTextContentPart(text: text)],
      ),
      runId: runId,
      parentRunId: parentRunId,
      state: state,
      context: context,
      tools: tools,
      forwardedProps: forwardedProps,
    );
  }

  Future<void> appendMessage(
    AgUiMessage message, {
    String? runId,
    String? parentRunId,
    Map<String, Object?> state = const <String, Object?>{},
    List<AgUiContextEntry> context = const <AgUiContextEntry>[],
    List<AgUiToolDefinition>? tools,
    Map<String, Object?> forwardedProps = const <String, Object?>{},
  }) async {
    if (_inProgress) {
      await stopGeneration();
    }

    _messages = <AgUiMessage>[..._messages, message];
    _session = _session.copyWith(messages: _toUiMessages(_messages));
    _inProgress = true;
    final cancelToken = AgUiTransportCancellationToken();
    _cancelToken = cancelToken;
    notifyListeners();

    final exportedTools = tools ?? await _exportAvailableTools();
    final runContext = <AgUiContextEntry>[
      ..._readableRegistry.toContextEntries(),
      ...context,
    ];
    final runForwardedProps = <String, Object?>{
      ..._runtime.properties,
      ...forwardedProps,
    };

    var input = RunAgentInput(
      threadId: _runtime.threadId,
      runId: runId ?? _idFactory(),
      parentRunId: parentRunId,
      messages: _messages,
      state: state,
      tools: exportedTools,
      context: runContext,
      forwardedProps: runForwardedProps,
    );

    try {
      await _consumeRun(input, cancelToken);

      var followUpTurns = 0;
      while (!cancelToken.isCancelled && followUpTurns < 8) {
        final result = await _toolRunLoop.drainEndedToolCalls(
          session: _session,
          availabilityContext: await _toolAvailabilityContext(),
          cancelToken: cancelToken,
        );
        _session = result.session;
        notifyListeners();

        if (!result.hasFollowUpMessages) {
          break;
        }

        _messages = <AgUiMessage>[..._messages, ...result.followUpMessages];
        _session = _session.copyWith(
          messages: <UiMessage>[
            ..._session.messages,
            ..._toUiMessages(result.followUpMessages),
          ],
        );
        notifyListeners();

        input = RunAgentInput(
          threadId: _runtime.threadId,
          runId: _idFactory(),
          parentRunId: input.runId,
          messages: _messages,
          state: state,
          tools: exportedTools,
          context: runContext,
          forwardedProps: runForwardedProps,
        );
        await _consumeRun(input, cancelToken);
        followUpTurns += 1;
      }
    } finally {
      if (identical(_cancelToken, cancelToken)) {
        _cancelToken = null;
      }
      _inProgress = false;
      notifyListeners();
    }
  }

  Future<void> reloadMessages({
    String? runId,
    Map<String, Object?> state = const <String, Object?>{},
  }) async {
    final lastUserIndex = _messages.lastIndexWhere(
      (message) => message.role == AgUiMessageRole.user,
    );
    if (lastUserIndex < 0) {
      return;
    }
    final message = _messages[lastUserIndex];
    setMessages(_messages.take(lastUserIndex).toList(growable: false));
    await appendMessage(message, runId: runId, state: state);
  }

  Future<void> stopGeneration() async {
    final cancelToken = _cancelToken;
    if (cancelToken == null) {
      return;
    }
    cancelToken.cancel();
    final activeRunId = _session.activeRunId;
    if (activeRunId != null) {
      final capabilities = await _transport.getCapabilities(
        agentId: _runtime.agent,
      );
      if (capabilities.supportsAbort) {
        await _transport.abort(threadId: _runtime.threadId, runId: activeRunId);
      }
    }
    _cancelToken = null;
    _inProgress = false;
    notifyListeners();
  }

  Future<List<AgUiToolDefinition>> _exportAvailableTools() async {
    if (_frontendToolRegistry.tools.isEmpty) {
      return const <AgUiToolDefinition>[];
    }
    final capabilities = await _transport.getCapabilities(
      agentId: _runtime.agent,
    );
    final context = FrontendToolAvailabilityContext(
      capabilities: _capabilityService.fromTransport(capabilities),
    );
    return _frontendToolRegistry.exportAvailableTools(context);
  }

  Future<FrontendToolAvailabilityContext> _toolAvailabilityContext() async {
    final capabilities = await _transport.getCapabilities(
      agentId: _runtime.agent,
    );
    return FrontendToolAvailabilityContext(
      capabilities: _capabilityService.fromTransport(capabilities),
    );
  }

  Future<void> _consumeRun(
    RunAgentInput input,
    AgUiTransportCancellationToken cancelToken,
  ) async {
    await for (final event in _transport.run(input, cancelToken: cancelToken)) {
      if (cancelToken.isCancelled) {
        break;
      }
      _session = _sessionController.reduce(_session, event);
      notifyListeners();
    }
  }
}

List<UiMessage> _toUiMessages(List<AgUiMessage> messages) {
  return messages
      .where(
        (message) =>
            message.role == AgUiMessageRole.user ||
            message.role == AgUiMessageRole.assistant ||
            message.role == AgUiMessageRole.tool,
      )
      .map(
        (message) => UiMessage(
          id: message.id,
          role: message.role,
          text: _textContent(message),
        ),
      )
      .toList(growable: false);
}

String _textContent(AgUiMessage message) {
  final buffer = StringBuffer();
  for (final part in message.content) {
    if (part is AgUiTextContentPart) {
      buffer.write(part.text);
    }
  }
  return buffer.toString();
}

String _timestampId() => DateTime.now().microsecondsSinceEpoch.toString();
