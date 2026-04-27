typedef AgUiAuthHeaderProvider = Future<Map<String, String>> Function();

class AgUiTransportConfig {
  const AgUiTransportConfig({
    required this.baseUrl,
    required this.authHeaderProvider,
    this.agentId = defaultAgentId,
    this.runPath = '/api/client/copilotkit/agent/maistack_agent/run',
    this.connectPath = '/api/client/copilotkit/agent/maistack_agent/connect',
    this.resumePath = '/api/client/copilotkit/agent/maistack_agent/resume',
    this.abortPath = '/api/client/copilotkit/agent/maistack_agent/stop',
    this.supportsResume = false,
    this.supportsAbort = false,
    this.supportsFrontendTools = false,
    this.supportedFrontendTools = const <String>{},
    this.connectionTimeout = const Duration(seconds: 30),
    this.readTimeout = const Duration(seconds: 45),
    this.controlTimeout = const Duration(seconds: 30),
  });

  static const defaultAgentId = 'maistack_agent';

  final Uri baseUrl;
  final AgUiAuthHeaderProvider authHeaderProvider;
  final String agentId;
  final String runPath;
  final String connectPath;
  final String resumePath;
  final String abortPath;
  final bool supportsResume;
  final bool supportsAbort;
  final bool supportsFrontendTools;
  final Set<String> supportedFrontendTools;
  final Duration connectionTimeout;
  final Duration readTimeout;
  final Duration controlTimeout;

  Uri get runUri => resolvePath(runPath);

  Uri get connectUri => resolvePath(connectPath);

  Uri get resumeUri => resolvePath(resumePath);

  Uri get abortUri => resolvePath(abortPath);

  Uri resolvePath(String path) {
    final normalizedSegments = path
        .split('/')
        .where((segment) => segment.isNotEmpty);
    return baseUrl.replace(
      pathSegments: [
        ...baseUrl.pathSegments.where((segment) => segment.isNotEmpty),
        ...normalizedSegments,
      ],
    );
  }
}
