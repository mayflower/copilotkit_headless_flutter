import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/copilotkit_headless_flutter.dart';

void main() {
  testWidgets('resolves custom action renderer with response callbacks', (
    tester,
  ) async {
    Map<String, Object?>? submitted;
    final registry = CopilotActionRendererRegistry(
      defaultRenderer: CopilotActionRenderer(
        id: 'default',
        builder: (context, contextData) => const Text('default'),
      ),
      renderers: <String, CopilotActionRenderer>{
        'confirm': CopilotActionRenderer(
          id: 'confirm',
          builder: (context, contextData) {
            return Directionality(
              textDirection: TextDirection.ltr,
              child: GestureDetector(
                onTap: () => contextData.submitResponse?.call(<String, Object?>{
                  'approved': true,
                }),
                child: Text(
                  '${contextData.toolName}:${contextData.status.name}',
                ),
              ),
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
            const ToolCallViewModel(
              id: 'call-1',
              name: 'confirm',
              stage: ToolCallStage.result,
              result: <String, Object?>{'status': 'waiting_for_response'},
            ),
            submitResponse: (response) => submitted = response,
          ),
        ),
      ),
    );

    expect(find.text('confirm:waitingForResponse'), findsOneWidget);
    await tester.tap(find.text('confirm:waitingForResponse'));
    expect(submitted, <String, Object?>{'approved': true});
  });

  testWidgets('uses fallback renderer for unknown tools', (tester) async {
    final registry = CopilotActionRendererRegistry(
      defaultRenderer: CopilotActionRenderer(
        id: 'default',
        builder: (context, contextData) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: Text('fallback:${contextData.toolName}'),
          );
        },
      ),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) => registry.build(
            context,
            const ToolCallViewModel(id: 'call-1', name: 'unknown'),
          ),
        ),
      ),
    );

    expect(find.text('fallback:unknown'), findsOneWidget);
  });
}
