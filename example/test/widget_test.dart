import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_copilot/flutter_copilot.dart';
import 'package:flutter_copilot_example/app/copilot_example_app.dart';

void main() {
  testWidgets('renders the copilot demo app', (tester) async {
    await tester.pumpWidget(
      CopilotApp(
        config: CopilotConfig(
          llm: FakeLlmAdapter(const <LlmToolCall>[]),
          settleDelay: Duration.zero,
        ),
        child: const CopilotExampleApp(),
      ),
    );

    expect(find.text('flutter_copilot'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Ask Copilot'), findsOneWidget);
    expect(find.text('OpenAI'), findsOneWidget);
  });
}
