import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_copilot/flutter_copilot.dart';

void main() {
  group('CopilotConfig.customActionTools', () {
    test('defaults to empty list', () {
      final config = CopilotConfig(llm: FakeLlmAdapter(const []));
      expect(config.customActionTools, isEmpty);
    });

    testWidgets('session sends built-in tools plus custom descriptors to the LLM',
        (tester) async {
      final adapter = _RecordingLlmAdapter(
        <LlmResponse>[
          const LlmResponse(
            toolCall: LlmToolCall(
              id: 'c1',
              name: 'done',
              arguments: <String, Object?>{'summary': 'Done.'},
            ),
          ),
        ],
      );
      const bookTrip = LlmTool(
        name: 'book_trip',
        description: 'Books a trip through the app.',
        parameters: <String, Object?>{
          'type': 'object',
          'properties': <String, Object?>{
            'where': <String, Object?>{'type': 'string'},
          },
          'required': <String>['where'],
        },
      );

      final session = CopilotSession(
        goal: 'Book a trip',
        config: CopilotConfig(
          llm: adapter,
          settleDelay: Duration.zero,
          customActionTools: <LlmTool>[bookTrip],
        ),
        emit: (_) {},
        capture: _FakeCapture(),
        executor: _FakeExecutor(),
      );

      await session.run();

      expect(adapter.toolBatches, hasLength(1));
      final tools = adapter.toolBatches.single;
      expect(tools, hasLength(copilotTools.length + 1));
      expect(
        tools.map((t) => t.name),
        containsAll(copilotTools.map((t) => t.name)),
      );
      expect(tools.map((t) => t.name), contains('book_trip'));
      final sentBookTrip = tools.firstWhere((t) => t.name == 'book_trip');
      expect(sentBookTrip, same(bookTrip));
    });

    testWidgets('a custom descriptor named like a built-in overrides it',
        (tester) async {
      final adapter = _RecordingLlmAdapter(
        <LlmResponse>[
          const LlmResponse(
            toolCall: LlmToolCall(
              id: 'c1',
              name: 'done',
              arguments: <String, Object?>{'summary': 'Done.'},
            ),
          ),
        ],
      );
      const stricterDone = LlmTool(
        name: 'done',
        description: 'Completes the run only after verifying the goal.',
        parameters: <String, Object?>{
          'type': 'object',
          'properties': <String, Object?>{
            'verified': <String, Object?>{'type': 'boolean'},
          },
          'required': <String>['verified'],
        },
      );

      final session = CopilotSession(
        goal: 'Do it',
        config: CopilotConfig(
          llm: adapter,
          settleDelay: Duration.zero,
          customActionTools: <LlmTool>[stricterDone],
        ),
        emit: (_) {},
        capture: _FakeCapture(),
        executor: _FakeExecutor(),
      );

      await session.run();

      final tools = adapter.toolBatches.single;
      final doneTools = tools.where((t) => t.name == 'done').toList();
      expect(doneTools, hasLength(1));
      expect(doneTools.single, same(stricterDone));
      // The built-in set itself is never modified.
      expect(copilotTools.where((t) => t.name == 'done'), hasLength(1));
    });
  });

  group('custom-first dispatch', () {
    testWidgets('registered name with non-built-in args goes to the handler',
        (tester) async {
      final executed = <CustomAction>[];
      final handler = _RecordingHandler(executed);

      final session = CopilotSession(
        goal: 'Tap something unusual',
        config: CopilotConfig(
          llm: FakeLlmAdapter(
            <LlmToolCall>[
              // `tap` is a built-in name, but its args are not built-in
              // shaped; the registered handler owns the argument shape.
              const LlmToolCall(
                id: 'c1',
                name: 'tap',
                arguments: <String, Object?>{'route': 'summary'},
              ),
              const LlmToolCall(
                id: 'c2',
                name: 'done',
                arguments: <String, Object?>{'summary': 'Done.'},
              ),
            ],
          ),
          settleDelay: Duration.zero,
          customActions: {'tap': handler},
        ),
        emit: (_) {},
        capture: _FakeCapture(),
        executor: _FakeExecutor(),
      );

      final result = await session.run();

      expect(result, isA<CopilotCompleted>());
      expect(executed, hasLength(1));
      expect(executed.first.name, 'tap');
      expect(executed.first.args, {'route': 'summary'});
    });

    testWidgets('a registered call executes exactly once', (tester) async {
      final executed = <CustomAction>[];
      final handler = _RecordingHandler(executed);
      final builtInExecuted = <CopilotAction>[];

      final session = CopilotSession(
        goal: 'Mix custom and built-in',
        config: CopilotConfig(
          llm: FakeLlmAdapter(
            <LlmToolCall>[
              const LlmToolCall(
                id: 'c1',
                name: 'my_tool',
                arguments: <String, Object?>{'x': 1},
              ),
              const LlmToolCall(
                id: 'c2',
                name: 'tap',
                arguments: <String, Object?>{'id': 'n1'},
              ),
              const LlmToolCall(
                id: 'c3',
                name: 'done',
                arguments: <String, Object?>{'summary': 'Done.'},
              ),
            ],
          ),
          settleDelay: Duration.zero,
          customActions: {'my_tool': handler},
        ),
        emit: (_) {},
        capture: _FakeCapture(),
        executor: _RecordingExecutor(builtInExecuted),
      );

      final result = await session.run();

      expect(result, isA<CopilotCompleted>());
      // The registered call must not be re-executed by the second pass.
      expect(executed, hasLength(1));
      // The unregistered built-in still goes through the executor.
      expect(builtInExecuted, hasLength(1));
      expect(builtInExecuted.single, isA<TapAction>());
    });
  });



  group('terminal semantics', () {
    testWidgets('done handler success completes with the handler message',
        (tester) async {
      final executed = <CustomAction>[];
      final handler = _RecordingHandler(
        executed,
        result: ActionResult.success('Verified against fresh state.'),
      );

      final session = CopilotSession(
        goal: 'Drive to done',
        config: CopilotConfig(
          llm: FakeLlmAdapter(
            <LlmToolCall>[
              const LlmToolCall(
                id: 'c1',
                name: 'done',
                arguments: <String, Object?>{'verified': true},
              ),
            ],
          ),
          settleDelay: Duration.zero,
          customActions: {'done': handler},
        ),
        emit: (_) {},
        capture: _FakeCapture(),
        executor: _FakeExecutor(),
      );

      final result = await session.run();

      expect(result, isA<CopilotCompleted>());
      expect(
        (result as CopilotCompleted).summary,
        'Verified against fresh state.',
      );
      expect(executed, hasLength(1));
    });

    testWidgets('recoverable done failure feeds back and the loop continues',
        (tester) async {
      var calls = 0;
      final handler = _FlippingHandler((action) async {
        calls++;
        return calls == 1
            ? ActionResult.failure('Not verified yet.', recoverable: true)
            : ActionResult.success('Verified.');
      });

      final adapter = _RecordingLlmAdapter(
        <LlmResponse>[
          const LlmResponse(
            toolCall: LlmToolCall(
              id: 'c1',
              name: 'done',
              arguments: <String, Object?>{'verified': false},
            ),
          ),
          const LlmResponse(
            toolCall: LlmToolCall(
              id: 'c2',
              name: 'done',
              arguments: <String, Object?>{'verified': true},
            ),
          ),
        ],
      );

      final session = CopilotSession(
        goal: 'Drive to a verified done',
        config: CopilotConfig(
          llm: adapter,
          settleDelay: Duration.zero,
          customActions: {'done': handler},
        ),
        emit: (_) {},
        capture: _FakeCapture(),
        executor: _FakeExecutor(),
      );

      final result = await session.run();

      expect(result, isA<CopilotCompleted>());
      expect((result as CopilotCompleted).summary, 'Verified.');
      expect(calls, 2);
      expect(adapter.toolBatches, hasLength(2));
    });

    testWidgets('fail handler ends the run with the handler message',
        (tester) async {
      final executed = <CustomAction>[];
      final handler = _RecordingHandler(
        executed,
        result: ActionResult.failure(
          'The goal is impossible for this client.',
          recoverable: false,
        ),
      );

      final session = CopilotSession(
        goal: 'An impossible goal',
        config: CopilotConfig(
          llm: FakeLlmAdapter(
            <LlmToolCall>[
              const LlmToolCall(
                id: 'c1',
                name: 'fail',
                arguments: <String, Object?>{'reason': 'impossible'},
              ),
            ],
          ),
          settleDelay: Duration.zero,
          customActions: {'fail': handler},
        ),
        emit: (_) {},
        capture: _FakeCapture(),
        executor: _FakeExecutor(),
      );

      final result = await session.run();

      expect(result, isA<CopilotFailed>());
      expect(
        (result as CopilotFailed).reason,
        'The goal is impossible for this client.',
      );
      expect(executed, hasLength(1));
    });
  });
}

/// Scripted adapter that records every tool list it is asked with.
class _RecordingLlmAdapter implements LlmAdapter {
  _RecordingLlmAdapter(this.responses);

  final List<LlmResponse> responses;
  final List<List<LlmTool>> toolBatches = <List<LlmTool>>[];
  int _index = 0;

  @override
  Future<LlmResponse> complete({
    required List<LlmMessage> messages,
    required List<LlmTool> tools,
  }) async {
    toolBatches.add(tools);
    if (_index >= responses.length) {
      return responses.last;
    }
    return responses[_index++];
  }
}

class _RecordingHandler implements CustomActionHandler {
  _RecordingHandler(this.actions, {ActionResult? result})
      : _result = result ?? ActionResult.success('ok');

  final List<CustomAction> actions;
  final ActionResult _result;

  @override
  Future<ActionResult> execute(CustomAction action) async {
    actions.add(action);
    return _result;
  }
}

class _FlippingHandler implements CustomActionHandler {
  _FlippingHandler(this._execute);

  final Future<ActionResult> Function(CustomAction action) _execute;

  @override
  Future<ActionResult> execute(CustomAction action) => _execute(action);
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
