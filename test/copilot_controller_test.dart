import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_copilot/flutter_copilot.dart';

void main() {
  test('blank goals fail before calling the LLM', () async {
    final controller = CopilotController(
      CopilotConfig(llm: FakeLlmAdapter(const <LlmToolCall>[])),
    );
    addTearDown(controller.dispose);

    final result = await controller.run('   ');

    expect(result, isA<CopilotFailed>());
    expect((result as CopilotFailed).reason, 'Goal cannot be empty.');
  });

  testWidgets('of throws a helpful error without CopilotApp', (tester) async {
    late Object error;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          try {
            CopilotController.of(context);
          } catch (caught) {
            error = caught;
          }
          return const SizedBox.shrink();
        },
      ),
    );

    expect(error, isA<StateError>());
  });

  testWidgets('rejects overlapping runs', (tester) async {
    final llm = _PendingLlmAdapter();
    final controller = CopilotController(CopilotConfig(llm: llm));
    addTearDown(controller.dispose);

    final first = controller.run('first goal');
    await tester.pump();

    final second = await controller.run('second goal');
    llm.completeWithDone();

    expect(second, isA<CopilotFailed>());
    expect(
        (second as CopilotFailed).reason, 'A copilot run is already active.');
    expect(await first, isA<CopilotCompleted>());
  });
}

class _PendingLlmAdapter implements LlmAdapter {
  final _completer = Completer<LlmResponse>();

  @override
  Future<LlmResponse> complete({
    required List<LlmMessage> messages,
    required List<LlmTool> tools,
  }) {
    return _completer.future;
  }

  void completeWithDone() {
    _completer.complete(
      const LlmResponse(
        toolCall: LlmToolCall(
          id: 'done',
          name: 'done',
          arguments: <String, Object?>{'summary': 'Finished.'},
        ),
      ),
    );
  }
}
