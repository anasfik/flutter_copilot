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

    expect(find.text('Copilot demo'), findsOneWidget);
    expect(find.text('Ask copilot'), findsOneWidget);
    expect(find.text('Dark mode is off'), findsOneWidget);
  });
}
