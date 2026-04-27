import 'dart:convert';

import 'package:copilotkit_headless_flutter/copilotkit_headless_flutter.dart'
    show
        CopilotAction,
        CopilotActionParameter,
        CopilotActionParameterType,
        CopilotActionRegistry,
        CopilotActionResult,
        FrontendTool,
        FrontendToolAvailability,
        FrontendToolAvailabilityContext,
        FrontendToolExecutionContext,
        FrontendToolExecutionResult,
        FrontendToolExecutor,
        FrontendToolRegistry,
        ToolCallViewModel;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FrontendToolExecutor', () {
    test('executes registered tools and returns AG-UI tool messages', () async {
      final executor = FrontendToolExecutor(
        registry: FrontendToolRegistry(
          tools: const <FrontendTool>[_EchoTool()],
        ),
      );

      final message = await executor.execute(
        const ToolCallViewModel(
          id: 'call-1',
          name: 'echo_tool',
          arguments: <String, Object?>{'text': 'hello'},
        ),
        context: const FrontendToolExecutionContext(),
      );

      expect(message.role.name, 'tool');
      expect(message.metadata['toolCallId'], 'call-1');
      expect(jsonDecode(message.toJson()['content']! as String), {
        'echo': 'hello',
      });
    });

    test('returns structured tool errors for unknown tools', () async {
      final executor = FrontendToolExecutor(
        registry: FrontendToolRegistry(tools: <FrontendTool>[]),
      );

      final message = await executor.execute(
        const ToolCallViewModel(id: 'call-1', name: 'missing_tool'),
        context: const FrontendToolExecutionContext(),
      );

      expect(message.metadata['error'], 'true');
      expect(message.metadata['toolCallId'], 'call-1');
    });

    test(
      'executes registered Copilot actions through registry adapter',
      () async {
        final registry = CopilotActionRegistry(
          actions: <CopilotAction>[
            CopilotAction(
              name: 'echo_action',
              parameters: const <CopilotActionParameter>[
                CopilotActionParameter(
                  name: 'text',
                  type: CopilotActionParameterType.string,
                ),
              ],
              handler: (args, context) async {
                return CopilotActionResult(
                  payload: <String, Object?>{'echo': args['text']},
                );
              },
            ),
          ],
        );
        final executor = FrontendToolExecutor(
          registry: registry.toFrontendToolRegistry(),
        );

        final message = await executor.execute(
          const ToolCallViewModel(
            id: 'call-2',
            name: 'echo_action',
            arguments: <String, Object?>{'text': 'hello'},
          ),
          context: const FrontendToolExecutionContext(),
        );

        expect(message.metadata['toolCallId'], 'call-2');
        expect(jsonDecode(message.toJson()['content']! as String), {
          'echo': 'hello',
        });
      },
    );
  });
}

class _EchoTool extends FrontendTool {
  const _EchoTool();

  @override
  String get name => 'echo_tool';

  @override
  String? get description => 'Echoes a text argument.';

  @override
  Map<String, Object?> get parametersSchema {
    return const <String, Object?>{
      'type': 'object',
      'properties': <String, Object?>{
        'text': <String, Object?>{'type': 'string'},
      },
    };
  }

  @override
  FrontendToolAvailability availability(
    FrontendToolAvailabilityContext context,
  ) {
    return const FrontendToolAvailability.available();
  }

  @override
  Future<FrontendToolExecutionResult> execute(
    Map<String, Object?> args, {
    required FrontendToolExecutionContext context,
    cancelToken,
  }) async {
    return FrontendToolExecutionResult(
      payload: <String, Object?>{'echo': args['text']},
    );
  }
}
