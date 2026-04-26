import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/copilotkit_headless_flutter.dart';

void main() {
  group('CopilotToolRunLoop', () {
    test(
      'executes ended local tool calls once and emits follow-up messages',
      () async {
        var executions = 0;
        final registry = CopilotActionRegistry(
          actions: <CopilotAction>[
            CopilotAction(
              name: 'echo',
              parameters: const <CopilotActionParameter>[
                CopilotActionParameter(
                  name: 'text',
                  type: CopilotActionParameterType.string,
                ),
              ],
              handler: (args, context) async {
                executions += 1;
                return CopilotActionResult(
                  payload: <String, Object?>{'echo': args['text']},
                );
              },
            ),
          ],
        );
        final runLoop = CopilotToolRunLoop(
          registry: registry.toFrontendToolRegistry(),
        );
        final session = _sessionWithCall(
          const ToolCallViewModel(
            id: 'call-1',
            name: 'echo',
            stage: ToolCallStage.ended,
            arguments: <String, Object?>{'text': 'hello'},
          ),
        );

        final first = await runLoop.drainEndedToolCalls(
          session: session,
          availabilityContext: _availableContext('echo'),
        );
        final second = await runLoop.drainEndedToolCalls(
          session: first.session,
          availabilityContext: _availableContext('echo'),
        );

        expect(executions, 1);
        expect(first.followUpMessages, hasLength(1));
        expect(first.session.toolCalls['call-1']?.stage, ToolCallStage.result);
        expect(first.session.toolCalls['call-1']?.result, <String, Object?>{
          'echo': 'hello',
        });
        expect(second.followUpMessages, isEmpty);
      },
    );

    test('respects followUp false while still marking local result', () async {
      final registry = CopilotActionRegistry(
        actions: <CopilotAction>[
          CopilotAction(
            name: 'local_only',
            followUp: false,
            handler: (args, context) async {
              return const CopilotActionResult(
                payload: <String, Object?>{'done': true},
              );
            },
          ),
        ],
      );
      final result =
          await CopilotToolRunLoop(
            registry: registry.toFrontendToolRegistry(),
          ).drainEndedToolCalls(
            session: _sessionWithCall(
              const ToolCallViewModel(
                id: 'call-1',
                name: 'local_only',
                stage: ToolCallStage.ended,
              ),
            ),
            availabilityContext: _availableContext('local_only'),
          );

      expect(result.followUpMessages, isEmpty);
      expect(result.session.toolCalls['call-1']?.result, <String, Object?>{
        'done': true,
      });
    });

    test('does not execute remote-only actions locally', () async {
      var executed = false;
      final registry = CopilotActionRegistry(
        actions: <CopilotAction>[
          CopilotAction(
            name: 'remote_action',
            available: CopilotActionAvailabilityMode.remote,
            handler: (args, context) async {
              executed = true;
              return const CopilotActionResult();
            },
          ),
        ],
      );

      final result =
          await CopilotToolRunLoop(
            registry: registry.toFrontendToolRegistry(),
          ).drainEndedToolCalls(
            session: _sessionWithCall(
              const ToolCallViewModel(
                id: 'call-1',
                name: 'remote_action',
                stage: ToolCallStage.ended,
              ),
            ),
            availabilityContext: _availableContext('remote_action'),
          );

      expect(executed, isFalse);
      expect(result.followUpMessages, isEmpty);
      expect(result.session.toolCalls['call-1']?.result, <String, Object?>{
        'status': 'remote_only',
        'message': 'Tool "remote_action" is remote-only.',
      });
    });

    test('emits stable error payloads for unavailable tools', () async {
      final result =
          await CopilotToolRunLoop(
            registry: CopilotActionRegistry(
              actions: <CopilotAction>[
                CopilotAction(
                  name: 'needs_capability',
                  handler: (args, context) async => const CopilotActionResult(),
                ),
              ],
            ).toFrontendToolRegistry(),
          ).drainEndedToolCalls(
            session: _sessionWithCall(
              const ToolCallViewModel(
                id: 'call-1',
                name: 'needs_capability',
                stage: ToolCallStage.ended,
              ),
            ),
            availabilityContext: const FrontendToolAvailabilityContext(
              capabilities: CapabilitySnapshot(
                frontendTools: CapabilityAvailability.unavailable,
              ),
            ),
          );

      final payload =
          jsonDecode(
                result.followUpMessages.single.toJson()['content']! as String,
              )
              as Map<String, Object?>;
      expect(payload['error'], isA<Map<String, Object?>>());
      expect(
        (payload['error']! as Map<String, Object?>)['code'],
        'disabled_by_capability',
      );
    });

    test(
      'waits for user response for renderAndWaitForResponse actions',
      () async {
        final coordinator = CopilotActionResponseCoordinator();
        final registry = CopilotActionRegistry(
          actions: <CopilotAction>[
            CopilotAction(
              name: 'confirm',
              renderMode: CopilotActionRenderMode.renderAndWaitForResponse,
              handler: (args, context) async => const CopilotActionResult(),
            ),
          ],
        );
        final runLoop = CopilotToolRunLoop(
          registry: registry.toFrontendToolRegistry(),
          responseCoordinator: coordinator,
        );

        final future = runLoop.drainEndedToolCalls(
          session: _sessionWithCall(
            const ToolCallViewModel(
              id: 'call-1',
              name: 'confirm',
              stage: ToolCallStage.ended,
              arguments: <String, Object?>{'title': 'Proceed?'},
            ),
          ),
          availabilityContext: _availableContext('confirm'),
        );

        await Future<void>.delayed(Duration.zero);
        expect(coordinator.pendingRequests.single.toolCallId, 'call-1');

        expect(
          coordinator.complete('call-1', <String, Object?>{'approved': true}),
          isTrue,
        );
        final result = await future;

        expect(result.followUpMessages, hasLength(1));
        expect(result.session.toolCalls['call-1']?.result, <String, Object?>{
          'approved': true,
        });
      },
    );
  });
}

ThreadSession _sessionWithCall(ToolCallViewModel call) {
  return ThreadSession.initial(
    'thread-1',
  ).copyWith(toolCalls: <String, ToolCallViewModel>{call.id: call});
}

FrontendToolAvailabilityContext _availableContext(String toolName) {
  return FrontendToolAvailabilityContext(
    capabilities: CapabilitySnapshot(
      frontendTools: CapabilityAvailability.available,
      toolCapabilities: <String, CapabilityAvailability>{
        toolName: CapabilityAvailability.available,
      },
    ),
  );
}
