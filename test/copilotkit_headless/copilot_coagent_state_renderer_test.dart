import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/copilotkit_headless_flutter.dart';

void main() {
  testWidgets('resolves node-specific coagent state renderer', (tester) async {
    final registry = CopilotCoAgentStateRendererRegistry(
      defaultRenderer: CopilotCoAgentStateRenderer(
        id: 'default',
        builder: (context, contextData) {
          return Text('default:${contextData.scope.agentId}');
        },
      ),
      renderers: <String, CopilotCoAgentStateRenderer>{
        'agent-a/draft': CopilotCoAgentStateRenderer(
          id: 'draft',
          builder: (context, contextData) {
            return Text(
              '${contextData.data['title']}:${contextData.status.name}',
            );
          },
        ),
      },
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) => registry.build(
            context,
            scope: const CopilotCoAgentScope(
              agentId: 'agent-a',
              nodeId: 'draft',
            ),
            data: const <String, Object?>{'title': 'Plan'},
            status: CopilotCoAgentStateRenderStatus.running,
          ),
        ),
      ),
    );

    expect(find.text('Plan:running'), findsOneWidget);
  });
}
