typedef AgUiAuthHeaderProvider = Future<Map<String, String>> Function();

class AgUiTransportConfig {
  const AgUiTransportConfig({
    required this.baseUrl,
    required this.authHeaderProvider,
    this.runPath = '/api/mobile/agui/run',
    this.connectPath = '/api/mobile/agui/connect',
    this.resumePath = '/api/mobile/agui/resume',
    this.abortPath = '/api/mobile/agui/abort',
    this.supportsResume = true,
    this.supportsAbort = false,
    this.supportsFrontendTools = false,
    this.supportedFrontendTools = const <String>{},
    this.connectionTimeout = const Duration(seconds: 30),
    this.readTimeout = const Duration(seconds: 45),
    this.controlTimeout = const Duration(seconds: 30),
  });

  final Uri baseUrl;
  final AgUiAuthHeaderProvider authHeaderProvider;
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
