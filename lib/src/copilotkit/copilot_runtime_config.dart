class CopilotRuntimeConfig {
  const CopilotRuntimeConfig({
    required this.threadId,
    this.agent,
    this.properties = const <String, Object?>{},
    this.headers = const <String, String>{},
  });

  final String threadId;
  final String? agent;
  final Map<String, Object?> properties;
  final Map<String, String> headers;

  CopilotRuntimeConfig copyWith({
    String? threadId,
    Object? agent = _unset,
    Map<String, Object?>? properties,
    Map<String, String>? headers,
  }) {
    return CopilotRuntimeConfig(
      threadId: threadId ?? this.threadId,
      agent: identical(agent, _unset) ? this.agent : agent as String?,
      properties: properties ?? this.properties,
      headers: headers ?? this.headers,
    );
  }
}

const Object _unset = Object();
