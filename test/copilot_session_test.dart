import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_copilot/flutter_copilot.dart';

void main() {
  testWidgets('completes a fake multi-step plan', (tester) async {
    final session = CopilotSession(
      goal: 'Open settings',
      config: CopilotConfig(
        llm: FakeLlmAdapter(
          <LlmToolCall>[
            const LlmToolCall(
                id: 'c1',
                name: 'tap',
                arguments: <String, Object?>{'id': 'n1'}),
            const LlmToolCall(
              id: 'c2',
              name: 'done',
              arguments: <String, Object?>{'summary': 'Settings opened.'},
            ),
          ],
        ),
        settleDelay: Duration.zero,
      ),
      emit: (_) {},
      capture: _FakeCapture(),
      executor: _FakeExecutor(),
    );

    final result = await session.run();

    expect(result, isA<CopilotCompleted>());
  });

  testWidgets('reports llm request errors and finishes', (tester) async {
    final events = <CopilotEvent>[];
    final session = CopilotSession(
      goal: 'Open settings',
      config: CopilotConfig(
        llm: _ThrowingLlmAdapter(),
        settleDelay: Duration.zero,
      ),
      emit: events.add,
      capture: _FakeCapture(),
      executor: _FakeExecutor(),
    );

    final result = await session.run();

    expect(result, isA<CopilotFailed>());
    expect(events.whereType<CopilotLlmRequestStarted>(), hasLength(1));
    expect(events.whereType<CopilotLlmRequestFailed>(), hasLength(1));
    expect(events.last, isA<CopilotFinished>());
  });

  testWidgets('executes multiple non-terminal tool calls from one response',
      (tester) async {
    final executed = <CopilotAction>[];
    final session = CopilotSession(
      goal: 'Tap settings twice',
      config: CopilotConfig(
        llm: _BatchThenDoneLlmAdapter(),
        settleDelay: Duration.zero,
      ),
      emit: (_) {},
      capture: _FakeCapture(),
      executor: _RecordingExecutor(executed),
    );

    final result = await session.run();

    expect(result, isA<CopilotCompleted>());
    expect(executed, hasLength(2));
  });

  testWidgets('stops on non-recoverable action failures', (tester) async {
    final session = CopilotSession(
      goal: 'Tap settings',
      config: CopilotConfig(
        llm: FakeLlmAdapter(
          <LlmToolCall>[
            const LlmToolCall(
              id: 'c1',
              name: 'tap',
              arguments: <String, Object?>{'id': 'n1'},
            ),
          ],
        ),
        settleDelay: Duration.zero,
      ),
      emit: (_) {},
      capture: _FakeCapture(),
      executor: _FailingExecutor(),
    );

    final result = await session.run();

    expect(result, isA<CopilotFailed>());
    expect((result as CopilotFailed).reason, 'fatal action failure');
  });
}

class _FakeCapture extends SceneCapture {
  @override
  SceneGraph capture() {
    return SceneGraph(
      nodes: const <SceneNode>[
        SceneNode(
          id: 'n1',
          semanticsId: 1,
          rect: Rect.fromLTWH(0, 0, 120, 48),
          label: 'Settings',
          actions: <SceneAction>{SceneAction.tap},
        ),
      ],
      idToSemanticsId: const <String, int>{'n1': 1},
    );
  }
}

class _FakeExecutor extends ActionExecutor {
  @override
  Future<ActionResult> execute(
      CopilotAction action, SceneGraph latestScene) async {
    return ActionResult.success('ok');
  }
}

class _ThrowingLlmAdapter implements LlmAdapter {
  @override
  Future<LlmResponse> complete({
    required List<LlmMessage> messages,
    required List<LlmTool> tools,
  }) async {
    throw const LlmException('network unavailable');
  }
}

class _BatchThenDoneLlmAdapter implements LlmAdapter {
  var _done = false;

  @override
  Future<LlmResponse> complete({
    required List<LlmMessage> messages,
    required List<LlmTool> tools,
  }) async {
    if (_done) {
      return const LlmResponse(
        toolCall: LlmToolCall(
          id: 'done',
          name: 'done',
          arguments: <String, Object?>{'summary': 'Finished.'},
        ),
      );
    }
    _done = true;
    return const LlmResponse(
      toolCalls: <LlmToolCall>[
        LlmToolCall(
          id: 'c1',
          name: 'tap',
          arguments: <String, Object?>{'id': 'n1'},
        ),
        LlmToolCall(
          id: 'c2',
          name: 'tap',
          arguments: <String, Object?>{'id': 'n1'},
        ),
      ],
    );
  }
}

class _RecordingExecutor extends ActionExecutor {
  _RecordingExecutor(this.actions);

  final List<CopilotAction> actions;

  @override
  Future<ActionResult> execute(
      CopilotAction action, SceneGraph latestScene) async {
    actions.add(action);
    return ActionResult.success('ok');
  }
}

class _FailingExecutor extends ActionExecutor {
  @override
  Future<ActionResult> execute(
      CopilotAction action, SceneGraph latestScene) async {
    return ActionResult.failure(
      'fatal action failure',
      recoverable: false,
    );
  }
}
