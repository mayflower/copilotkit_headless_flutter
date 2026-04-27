import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/copilotkit_headless_flutter.dart';

void main() {
  group('CopilotAction', () {
    test('exports CopilotKit-style parameters as AG-UI tool schema', () {
      final action = CopilotAction(
        name: 'addTodoItem',
        description: 'Add a new todo item to the list',
        parameters: const <CopilotActionParameter>[
          CopilotActionParameter(
            name: 'todoText',
            type: CopilotActionParameterType.string,
            description: 'The text of the todo item to add',
          ),
          CopilotActionParameter(
            name: 'labels',
            type: CopilotActionParameterType.stringArray,
            required: false,
          ),
        ],
        available: CopilotActionAvailabilityMode.remote,
        followUp: false,
        renderMode: CopilotActionRenderMode.render,
        handler: (args, context) async => const CopilotActionResult(),
      );

      final definition = action.toToolDefinition();

      expect(definition.name, 'addTodoItem');
      expect(definition.description, 'Add a new todo item to the list');
      final parameters = definition.parameters as Map<String, Object?>;
      expect(parameters['type'], 'object');
      expect(parameters['required'], <String>['todoText']);
      final properties = parameters['properties'] as Map<String, Object?>;
      expect(properties['todoText'], <String, Object?>{
        'type': 'string',
        'description': 'The text of the todo item to add',
      });
      expect(properties['labels'], <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{'type': 'string'},
      });
      expect(parameters['x-copilotkit'], <String, Object?>{
        'available': 'remote',
        'followUp': false,
        'renderMode': 'render',
      });
    });

    test(
      'registry adapts actions to existing frontend tool execution path',
      () async {
        final registry = CopilotActionRegistry(
          actions: <CopilotAction>[
            CopilotAction(
              name: 'selectEmployee',
              parameters: const <CopilotActionParameter>[
                CopilotActionParameter(
                  name: 'employeeId',
                  type: CopilotActionParameterType.string,
                ),
              ],
              handler: (args, context) async {
                return CopilotActionResult(
                  payload: <String, Object?>{
                    'selected': args['employeeId'],
                    'cancelable': context.cancelToken != null,
                  },
                );
              },
            ),
          ],
        );

        final frontendRegistry = registry.toFrontendToolRegistry();
        final exported = frontendRegistry.exportAvailableTools(
          const FrontendToolAvailabilityContext(
            capabilities: CapabilitySnapshot(
              frontendTools: CapabilityAvailability.available,
              toolCapabilities: <String, CapabilityAvailability>{
                'selectEmployee': CapabilityAvailability.available,
              },
            ),
          ),
        );

        expect(exported.map((tool) => tool.name), <String>['selectEmployee']);

        final result = await frontendRegistry
            .toolNamed('selectEmployee')!
            .execute(
              <String, Object?>{'employeeId': 'employee-1'},
              context: const FrontendToolExecutionContext(),
              cancelToken: AgUiTransportCancellationToken(),
            );

        expect(result.payload, <String, Object?>{
          'selected': 'employee-1',
          'cancelable': true,
        });
      },
    );

    test(
      'disabled actions are not exported even when capability allows them',
      () {
        final registry = CopilotActionRegistry(
          actions: <CopilotAction>[
            CopilotAction(
              name: 'disabledAction',
              available: CopilotActionAvailabilityMode.disabled,
              handler: (args, context) async => const CopilotActionResult(),
            ),
          ],
        );

        final exported = registry.exportAvailableTools(
          const FrontendToolAvailabilityContext(
            capabilities: CapabilitySnapshot(
              frontendTools: CapabilityAvailability.available,
              toolCapabilities: <String, CapabilityAvailability>{
                'disabledAction': CapabilityAvailability.available,
              },
            ),
          ),
        );

        expect(exported, isEmpty);
      },
    );
  });
}
