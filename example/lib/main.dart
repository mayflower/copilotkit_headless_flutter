import 'dart:async';
import 'dart:convert';

import 'package:copilotkit_headless_flutter/copilotkit_headless_flutter.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CopilotKit Headless Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  late final CopilotHeadlessChatController _controller;
  final TextEditingController _textController = TextEditingController(
    text: 'Where am I working from today?',
  );

  @override
  void initState() {
    super.initState();
    final actions = CopilotActionRegistry(
      actions: <CopilotAction>[
        CopilotAction(
          name: 'get_current_city',
          description: 'Read the city selected in the Flutter client.',
          handler: (args, context) async {
            return const CopilotActionResult(
              payload: <String, Object?>{'city': 'Wuerzburg'},
            );
          },
        ),
      ],
    );

    _controller = CopilotHeadlessChatController(
      transport: const MockAgentTransport(),
      runtime: const CopilotRuntimeConfig(
        threadId: 'example-thread',
        agent: 'local-demo',
      ),
      actionRegistry: actions,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _controller.inProgress) {
      return;
    }
    await _controller.submitUserMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CopilotKit Headless Flutter')),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final session = _controller.session;
          final chat = Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    for (final message in session.messages)
                      _MessageBubble(message: message),
                    if (_controller.inProgress) const LinearProgressIndicator(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        onSubmitted: (_) => unawaited(_send()),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Message',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _controller.inProgress
                          ? null
                          : () => unawaited(_send()),
                      child: const Text('Send'),
                    ),
                  ],
                ),
              ),
            ],
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 760) {
                return Column(
                  children: <Widget>[
                    Expanded(child: chat),
                    SizedBox(height: 280, child: _Inspector(session: session)),
                  ],
                );
              }
              return Row(
                children: <Widget>[
                  Expanded(flex: 3, child: chat),
                  SizedBox(width: 360, child: _Inspector(session: session)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final UiMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == AgUiMessageRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(message.text),
      ),
    );
  }
}

class _Inspector extends StatelessWidget {
  const _Inspector({required this.session});

  final ThreadSession session;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('Runtime', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Run status: ${session.runStatus.name}'),
          Text('Connection: ${session.connectionStatus.name}'),
          const SizedBox(height: 24),
          Text('Tool calls', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final call in session.toolCalls.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(call.name),
              subtitle: Text('${call.stage.name}: ${call.result ?? ''}'),
            ),
          if (session.toolCalls.isEmpty) const Text('No tool calls yet.'),
          const SizedBox(height: 24),
          Text('Shared state', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SelectableText(
            const JsonEncoder.withIndent(
              '  ',
            ).convert(session.sharedState.data),
          ),
        ],
      ),
    );
  }
}

class MockAgentTransport extends AgentTransport {
  const MockAgentTransport();

  @override
  Stream<AgUiEventEnvelope> connect({
    required ConnectAgentInput input,
    AgUiTransportCancellationToken? cancelToken,
  }) async* {}

  @override
  Stream<AgUiEventEnvelope> run(
    RunAgentInput input, {
    AgUiTransportCancellationToken? cancelToken,
  }) async* {
    yield _event(<String, Object?>{
      'type': 'RUN_STARTED',
      'threadId': input.threadId,
      'runId': input.runId,
    });

    final toolResult = _lastToolResult(input.messages);
    if (toolResult == null) {
      yield _event(<String, Object?>{
        'type': 'STATE_SNAPSHOT',
        'snapshot': <String, Object?>{
          'agent': 'local-demo',
          'phase': 'requesting_client_context',
        },
      });
      yield _event(<String, Object?>{
        'type': 'TOOL_CALL_START',
        'toolCallId': 'city-call',
        'toolCallName': 'get_current_city',
      });
      yield _event(<String, Object?>{
        'type': 'TOOL_CALL_ARGS',
        'toolCallId': 'city-call',
        'toolCallName': 'get_current_city',
        'args': <String, Object?>{},
      });
      yield _event(<String, Object?>{
        'type': 'TOOL_CALL_END',
        'toolCallId': 'city-call',
        'toolCallName': 'get_current_city',
      });
      return;
    }

    final city = toolResult['city'] ?? 'the selected city';
    yield _event(<String, Object?>{
      'type': 'STATE_SNAPSHOT',
      'snapshot': <String, Object?>{
        'agent': 'local-demo',
        'phase': 'answered',
        'city': city,
      },
    });
    yield _event(<String, Object?>{
      'type': 'MESSAGES_SNAPSHOT',
      'messages': <Object?>[
        ...input.messages.map((message) => message.toJson()),
        <String, Object?>{
          'id': 'assistant-${input.runId}',
          'role': 'assistant',
          'content': 'The Flutter client says you are working from $city.',
        },
      ],
    });
  }

  @override
  Future<AgUiCapabilitySet> getCapabilities({String? agentId}) async {
    return const AgUiCapabilitySet(
      supportsFrontendTools: true,
      supportedFrontendTools: <String>{'get_current_city'},
    );
  }

  @override
  Future<void> abort({required String threadId, required String runId}) async {}

  @override
  Future<AgUiResumeResult> resume(AgUiResumeRequest request) async {
    return AgUiResumeResult(
      threadId: request.threadId,
      runId: 'resumed-${request.interruptedRunId}',
    );
  }
}

Map<String, Object?>? _lastToolResult(List<AgUiMessage> messages) {
  for (final message in messages.reversed) {
    if (message.role != AgUiMessageRole.tool || message.content.isEmpty) {
      continue;
    }
    final content = message.content.first;
    if (content is! AgUiTextContentPart) {
      continue;
    }
    final decoded = jsonDecode(content.text);
    if (decoded is Map<String, Object?>) {
      return decoded;
    }
  }
  return null;
}

AgUiEventEnvelope _event(Map<String, Object?> payload) {
  return AgUiEventEnvelope.fromRawPayload(
    rawPayload: jsonEncode(payload),
    receivedAt: DateTime.now(),
  );
}
