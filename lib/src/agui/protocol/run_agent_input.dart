import 'agui_message.dart';

class AgUiContextEntry {
  const AgUiContextEntry({required this.description, required this.value});

  final String description;
  final String value;

  Map<String, Object?> toJson() => <String, Object?>{
    'description': description,
    'value': value,
  };
}

class AgUiToolDefinition {
  const AgUiToolDefinition({
    required this.name,
    required this.description,
    this.parameters,
    this.metadata,
  });

  final String name;
  final String description;
  final Object? parameters;
  final Map<String, Object?>? metadata;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'description': description,
    if (parameters != null) 'parameters': parameters,
    if (metadata != null && metadata!.isNotEmpty) 'metadata': metadata,
  };
}

class RunAgentInput {
  const RunAgentInput({
    required this.threadId,
    required this.runId,
    required this.messages,
    this.parentRunId,
    this.state = const <String, Object?>{},
    this.tools = const <AgUiToolDefinition>[],
    this.context = const <AgUiContextEntry>[],
    this.forwardedProps = const <String, Object?>{},
  });

  factory RunAgentInput.userTextTurn({
    required String threadId,
    required String runId,
    required String messageId,
    required String text,
    String? parentRunId,
    Map<String, Object?> state = const <String, Object?>{},
    List<AgUiToolDefinition> tools = const <AgUiToolDefinition>[],
    List<AgUiContextEntry> context = const <AgUiContextEntry>[],
    Map<String, Object?> forwardedProps = const <String, Object?>{},
  }) {
    return RunAgentInput(
      threadId: threadId,
      runId: runId,
      parentRunId: parentRunId,
      messages: <AgUiMessage>[
        AgUiMessage(
          id: messageId,
          role: AgUiMessageRole.user,
          content: <AgUiMessageContentPart>[AgUiTextContentPart(text: text)],
        ),
      ],
      state: state,
      tools: tools,
      context: context,
      forwardedProps: forwardedProps,
    );
  }

  factory RunAgentInput.userMultimodalTurn({
    required String threadId,
    required String runId,
    required String messageId,
    required List<AgUiMessageContentPart> content,
    String? parentRunId,
    Map<String, Object?> state = const <String, Object?>{},
    List<AgUiToolDefinition> tools = const <AgUiToolDefinition>[],
    List<AgUiContextEntry> context = const <AgUiContextEntry>[],
    Map<String, Object?> forwardedProps = const <String, Object?>{},
  }) {
    return RunAgentInput(
      threadId: threadId,
      runId: runId,
      parentRunId: parentRunId,
      messages: <AgUiMessage>[
        AgUiMessage(
          id: messageId,
          role: AgUiMessageRole.user,
          content: _normalizeMultimodalContent(content),
        ),
      ],
      state: state,
      tools: tools,
      context: context,
      forwardedProps: forwardedProps,
    );
  }

  final String threadId;
  final String runId;
  final String? parentRunId;
  final List<AgUiMessage> messages;
  final Map<String, Object?> state;
  final List<AgUiToolDefinition> tools;
  final List<AgUiContextEntry> context;
  final Map<String, Object?> forwardedProps;

  Map<String, Object?> toJson() => <String, Object?>{
    'threadId': threadId,
    'runId': runId,
    if (parentRunId != null) 'parentRunId': parentRunId,
    'messages': messages
        .map((message) => message.toJson())
        .toList(growable: false),
    'state': state,
    'tools': tools.map((tool) => tool.toJson()).toList(growable: false),
    'context': context.map((entry) => entry.toJson()).toList(growable: false),
    'forwardedProps': forwardedProps,
  };

  static List<AgUiMessageContentPart> _normalizeMultimodalContent(
    List<AgUiMessageContentPart> content,
  ) {
    return content
        .where(
          (part) => part is! AgUiTextContentPart || part.text.trim().isNotEmpty,
        )
        .toList(growable: false);
  }
}
