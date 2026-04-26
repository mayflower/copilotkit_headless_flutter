import 'dart:async';

import '../protocol/agui_event_envelope.dart';
import '../protocol/connect_agent_input.dart';
import '../protocol/run_agent_input.dart';

class AgUiTransportCancellationToken {
  final StreamController<void> _controller = StreamController<void>.broadcast(
    sync: true,
  );
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  Stream<void> get stream => _controller.stream;

  void cancel() {
    if (_isCancelled) {
      return;
    }
    _isCancelled = true;
    _controller.add(null);
    unawaited(_controller.close());
  }
}

class AgUiCapabilitySet {
  const AgUiCapabilitySet({
    this.supportsCapabilityDiscovery = false,
    this.supportsAbort = false,
    this.supportsResume = false,
    this.supportsFrontendTools = false,
    this.supportedFrontendTools = const <String>{},
  });

  const AgUiCapabilitySet.none()
    : supportsCapabilityDiscovery = false,
      supportsAbort = false,
      supportsResume = false,
      supportsFrontendTools = false,
      supportedFrontendTools = const <String>{};

  final bool supportsCapabilityDiscovery;
  final bool supportsAbort;
  final bool supportsResume;
  final bool supportsFrontendTools;
  final Set<String> supportedFrontendTools;
}

class AgUiResumeRequest {
  const AgUiResumeRequest({
    required this.threadId,
    required this.interruptedRunId,
    required this.payload,
  });

  final String threadId;
  final String interruptedRunId;
  final Map<String, Object?> payload;
}

class AgUiResumeResult {
  const AgUiResumeResult({required this.threadId, required this.runId});

  final String threadId;
  final String runId;
}

abstract class AgentTransport {
  const AgentTransport();

  Stream<AgUiEventEnvelope> connect({
    required ConnectAgentInput input,
    AgUiTransportCancellationToken? cancelToken,
  });

  Stream<AgUiEventEnvelope> run(
    RunAgentInput input, {
    AgUiTransportCancellationToken? cancelToken,
  });

  Future<AgUiCapabilitySet> getCapabilities({String? agentId});

  Future<void> abort({required String threadId, required String runId});

  Future<AgUiResumeResult> resume(AgUiResumeRequest request);
}
