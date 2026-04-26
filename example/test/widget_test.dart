import 'package:copilotkit_headless_flutter_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the example app shell', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('CopilotKit Headless Flutter'), findsWidgets);
    expect(find.text('Runtime'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
