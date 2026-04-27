import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/copilotkit_headless_flutter.dart';

import '../agui/test_helpers/envelope_factory.dart';

void main() {
  group('CopilotHeadlessChatController', () {
    test(
      'submits messages with readable context, properties and tools',
      () async {
        final transport = _FakeTransport(
          capabilities: const AgUiCapabilitySet(
            supportsFrontendTools: true,
            supportedFrontendTools: <String>{'show_toast'},
          ),
          events: <AgUiEventEnvelope>[
            envelopeFromJson(<String, Object?>{
              'type': 'RUN_STARTED',
              'threadId': 'thread-1',
              'runId': 'run-1',
            }),
            envelopeFromJson(<String, Object?>{
              'type': 'TEXT_MESSAGE_START',
              'messageId': 'assistant-1',
              'role': 'assistant',
            }),
            envelopeFromJson(<String, Object?>{
              'type': 'TEXT_MESSAGE_CHUNK',
              'messageId': 'assistant-1',
              'delta': 'Done',
            }),
            envelopeFromJson(<String, Object?>{
              'type': 'RUN_FINISHED',
              'threadId': 'thread-1',
              'runId': 'run-1',
            }),
          ],
        );
        final readable = CopilotReadableRegistry(
          entries: const <CopilotReadable>[
            CopilotReadable(
              key: 'selection',
              description: 'Current selected asset',
              value: <String, Object?>{'id': 'asset-1'},
            ),
          ],
        );
        final controller = CopilotHeadlessChatController(
          transport: transport,
          runtime: const CopilotRuntimeConfig(
            threadId: 'thread-1',
            agent: 'mobile_agent',
            properties: <String, Object?>{'tenant': 'mai'},
          ),
          readableRegistry: readable,
          actionRegistry: CopilotActionRegistry(
            actions: <CopilotAction>[
              CopilotAction(
                name: 'show_toast',
                description: 'Show a toast',
                parameters: const <CopilotActionParameter>[
                  CopilotActionParameter(
                    name: 'message',
                    type: CopilotActionParameterType.string,
                  ),
                ],
                available: CopilotActionAvailabilityMode.remote,
                handler: (args, context) async => const CopilotActionResult(),
              ),
            ],
          ),
          idFactory: _sequence(<String>['message-1', 'run-1']),
        );

        await controller.submitUserMessage('Hello');

        final input = transport.lastRunInput!;
        expect(input.threadId, 'thread-1');
        expect(input.runId, 'run-1');
        expect(input.forwardedProps, <String, Object?>{'tenant': 'mai'});
        expect(input.context.single.description, contains('Key: selection'));
        expect(input.context.single.value, '{"id":"asset-1"}');
        expect(input.tools.map((tool) => tool.name), <String>['show_toast']);
        expect(controller.inProgress, isFalse);
        expect(controller.messages.single.id, 'message-1');
        expect(controller.visibleMessages.last.text, 'Done');
        expect(controller.session.runStatus, RunStatus.completed);
      },
    );

    test('set, delete and reset operate without UI widgets', () {
      final controller = CopilotHeadlessChatController(
        transport: _FakeTransport(),
        runtime: const CopilotRuntimeConfig(threadId: 'thread-1'),
      );

      controller.setMessages(const <AgUiMessage>[
        AgUiMessage(
          id: 'system-1',
          role: AgUiMessageRole.system,
          content: <AgUiMessageContentPart>[
            AgUiTextContentPart(text: 'hidden'),
          ],
        ),
        AgUiMessage(
          id: 'user-1',
          role: AgUiMessageRole.user,
          content: <AgUiMessageContentPart>[
            AgUiTextContentPart(text: 'visible'),
          ],
        ),
      ]);

      expect(controller.messages, hasLength(2));
      expect(controller.visibleMessages.map((message) => message.id), <String>[
        'user-1',
      ]);

      controller.deleteMessage('user-1');

      expect(controller.messages.map((message) => message.id), <String>[
        'system-1',
      ]);
      expect(controller.visibleMessages, isEmpty);

      controller.reset(threadId: 'thread-2');

      expect(controller.runtime.threadId, 'thread-2');
      expect(controller.messages, isEmpty);
      expect(controller.session.threadId, 'thread-2');
    });

    test(
      'executes local tool calls and sends follow-up tool messages',
      () async {
        final transport = _FakeTransport(
          capabilities: const AgUiCapabilitySet(
            supportsFrontendTools: true,
            supportedFrontendTools: <String>{'echo'},
          ),
          eventsByRun: <List<AgUiEventEnvelope>>[
            <AgUiEventEnvelope>[
              envelopeFromJson(<String, Object?>{
                'type': 'RUN_STARTED',
                'threadId': 'thread-1',
                'runId': 'run-1',
              }),
              envelopeFromJson(<String, Object?>{
                'type': 'TOOL_CALL_START',
                'toolCallId': 'call-1',
                'toolCallName': 'echo',
              }),
              envelopeFromJson(<String, Object?>{
                'type': 'TOOL_CALL_ARGS',
                'toolCallId': 'call-1',
                'args': <String, Object?>{'text': 'hello'},
              }),
              envelopeFromJson(<String, Object?>{
                'type': 'TOOL_CALL_END',
                'toolCallId': 'call-1',
              }),
              envelopeFromJson(<String, Object?>{
                'type': 'RUN_FINISHED',
                'threadId': 'thread-1',
                'runId': 'run-1',
              }),
            ],
            <AgUiEventEnvelope>[
              envelopeFromJson(<String, Object?>{
                'type': 'RUN_STARTED',
                'threadId': 'thread-1',
                'runId': 'run-2',
              }),
              envelopeFromJson(<String, Object?>{
                'type': 'TEXT_MESSAGE_START',
                'messageId': 'assistant-1',
                'role': 'assistant',
              }),
              envelopeFromJson(<String, Object?>{
                'type': 'TEXT_MESSAGE_CHUNK',
                'messageId': 'assistant-1',
                'delta': 'followed',
              }),
              envelopeFromJson(<String, Object?>{
                'type': 'RUN_FINISHED',
                'threadId': 'thread-1',
                'runId': 'run-2',
              }),
            ],
          ],
        );
        final controller = CopilotHeadlessChatController(
          transport: transport,
          runtime: const CopilotRuntimeConfig(threadId: 'thread-1'),
          actionRegistry: CopilotActionRegistry(
            actions: <CopilotAction>[
              CopilotAction(
                name: 'echo',
                handler: (args, context) async => CopilotActionResult(
                  payload: <String, Object?>{'echo': args['text']},
                ),
              ),
            ],
          ),
          idFactory: _sequence(<String>['message-1', 'run-1', 'run-2']),
        );

        await controller.submitUserMessage('Hello');

        expect(transport.runInputs, hasLength(2));
        expect(transport.runInputs.last.parentRunId, 'run-1');
        expect(
          transport.runInputs.last.messages.last.metadata['toolCallId'],
          'call-1',
        );
        expect(
          controller.session.toolCalls['call-1']?.stage,
          ToolCallStage.result,
        );
        expect(controller.visibleMessages.last.text, 'followed');
      },
    );
  });
}

class _FakeTransport extends AgentTransport {
  _FakeTransport({
    this.capabilities = const AgUiCapabilitySet.none(),
    this.events = const <AgUiEventEnvelope>[],
    this.eventsByRun = const <List<AgUiEventEnvelope>>[],
  });

  final AgUiCapabilitySet capabilities;
  final List<AgUiEventEnvelope> events;
  final List<List<AgUiEventEnvelope>> eventsByRun;
  final List<RunAgentInput> runInputs = <RunAgentInput>[];
  RunAgentInput? lastRunInput;

  @override
  Stream<AgUiEventEnvelope> connect({
    required ConnectAgentInput input,
    AgUiTransportCancellationToken? cancelToken,
  }) {
    return const Stream<AgUiEventEnvelope>.empty();
  }

  @override
  Stream<AgUiEventEnvelope> run(
    RunAgentInput input, {
    AgUiTransportCancellationToken? cancelToken,
  }) {
    final index = runInputs.length;
    runInputs.add(input);
    lastRunInput = input;
    if (eventsByRun.isNotEmpty && index < eventsByRun.length) {
      return Stream<AgUiEventEnvelope>.fromIterable(eventsByRun[index]);
    }
    return Stream<AgUiEventEnvelope>.fromIterable(events);
  }

  @override
  Future<AgUiCapabilitySet> getCapabilities({String? agentId}) async {
    return capabilities;
  }

  @override
  Future<void> abort({required String threadId, required String runId}) async {}

  @override
  Future<AgUiResumeResult> resume(AgUiResumeRequest request) async {
    return AgUiResumeResult(
      threadId: request.threadId,
      runId: request.interruptedRunId,
    );
  }
}

String Function() _sequence(List<String> ids) {
  var index = 0;
  return () => ids[index++];
}
