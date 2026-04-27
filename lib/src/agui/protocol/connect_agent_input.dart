import 'agui_json.dart';

class ConnectAgentInput {
  const ConnectAgentInput({
    required this.threadId,
    this.runId,
    this.forwardedProps = const <String, Object?>{},
  });

  final String threadId;
  final String? runId;
  final Map<String, Object?> forwardedProps;

  Map<String, Object?> toJson() => <String, Object?>{
    'threadId': threadId,
    if (runId != null) 'runId': runId,
    if (forwardedProps.isNotEmpty)
      'forwardedProps': normalizeObjectMap(forwardedProps),
  };
}
