import 'dart:convert';

import 'package:flutter/widgets.dart';

import 'actions/action_executor.dart';
import 'actions/copilot_action.dart';
import 'llm/llm_adapter.dart';
import 'llm/llm_message.dart';
import 'llm/llm_tool.dart';
import 'logging/copilot_event.dart';
import 'copilot_config.dart';
import 'copilot_run_result.dart';
import 'scene/scene_capture.dart';
import 'scene/scene_compressor.dart';
import 'scene/scene_graph.dart';

/// One autonomous observe-plan-act run.
class CopilotSession {
  /// Creates a copilot session.
  CopilotSession({
    required this.goal,
    required this.config,
    required this.emit,
    SceneCapture? capture,
    SceneCompressor? compressor,
    ActionExecutor? executor,
  })  : _capture = capture ?? SceneCapture(),
        _compressor = compressor ?? const SceneCompressor(),
        _executor = executor ?? ActionExecutor(capture: capture);

  /// User goal for this run.
  final String goal;

  /// Runtime configuration.
  final CopilotConfig config;

  /// Event sink used by the session.
  final void Function(CopilotEvent event) emit;
  final SceneCapture _capture;
  final SceneCompressor _compressor;
  final ActionExecutor _executor;

  /// Runs the session to a terminal result.
  Future<CopilotRunResult> run() async {
    emit(CopilotStarted(goal));
    final messages = <LlmMessage>[
      LlmMessage.system(_systemPrompt),
      LlmMessage.user('Goal: $goal'),
    ];

    for (var step = 0; step < config.maxSteps; step++) {
      final scene = _observe();
      emit(CopilotSceneCaptured(scene));
      messages.add(
          LlmMessage.user('Current screen JSON:\n${scene.toCompactJson()}'));

      final LlmResponse response;
      emit(CopilotLlmRequestStarted(step + 1));
      try {
        response =
            await config.llm.complete(messages: messages, tools: copilotTools);
      } catch (error) {
        final reason = 'LLM request failed: $error';
        emit(CopilotLlmRequestFailed(step + 1, reason));
        emit(CopilotFinished(reason));
        return CopilotFailed(reason);
      }
      emit(CopilotLlmRequestSucceeded(step + 1));

      final toolCalls = response.allToolCalls;
      if (toolCalls.isEmpty) {
        final result =
            CopilotFailed('Model did not call a tool: ${response.content}');
        emit(CopilotFinished(result.reason));
        return result;
      }

      final actionResults = <Map<String, Object?>>[];
      var latestScene = scene;
      for (final toolCall in toolCalls) {
        final CopilotAction action;
        try {
          action =
              CopilotAction.fromToolCall(toolCall.name, toolCall.arguments);
        } catch (error) {
          final reason = 'Model returned an invalid tool call: $error';
          emit(CopilotFinished(reason));
          return CopilotFailed(reason);
        }
        emit(CopilotActionPlanned(action));

        switch (action) {
          case DoneAction(:final summary):
            if (toolCalls.length > 1) {
              final reason = 'done must be the only tool call in a response.';
              emit(CopilotFinished(reason));
              return CopilotFailed(reason);
            }
            emit(CopilotFinished(summary));
            return CopilotCompleted(summary);
          case FailAction(:final reason):
            if (toolCalls.length > 1) {
              final message = 'fail must be the only tool call in a response.';
              emit(CopilotFinished(message));
              return CopilotFailed(message);
            }
            emit(CopilotFinished(reason));
            return CopilotFailed(reason);
          default:
            break;
        }

        final safety = config.safetyPolicy.evaluate(action, latestScene);
        if (!safety.allowed) {
          final reason = safety.reason ?? 'Action blocked by safety policy.';
          emit(CopilotFinished(reason));
          return CopilotFailed(reason);
        }

        final actionResult = await _executor.execute(action, latestScene);
        emit(CopilotActionExecuted(action, actionResult));
        actionResults.add(<String, Object?>{
          'tool': toolCall.name,
          'arguments': toolCall.arguments,
          'result': actionResult.toJson(),
        });
        if (!actionResult.success && !actionResult.recoverable) {
          emit(CopilotFinished(actionResult.message));
          return CopilotFailed(actionResult.message);
        }

        await _waitForUiSettle();
        latestScene = _observe();
      }

      messages.add(LlmMessage.assistant(
          'Selected actions JSON:\n${jsonEncode(actionResults)}'));
      messages.add(LlmMessage.user(
          'Action results JSON:\n${jsonEncode(actionResults.map((entry) => entry['result']).toList())}'));
    }

    emit(CopilotFinished('Maximum step count exceeded.'));
    return CopilotMaxStepsExceeded(config.maxSteps);
  }

  SceneGraph _observe() => _compressor.compress(_capture.capture());

  Future<void> _waitForUiSettle() async {
    if (config.settleDelay == Duration.zero) {
      await Future<void>.value();
      return;
    }

    final binding = WidgetsBinding.instance;
    if (binding.hasScheduledFrame) {
      await binding.endOfFrame;
    }
    await Future<void>.delayed(config.settleDelay);
  }
}

const _systemPrompt = '''
You are flutter_copilot: an invisible automation agent running inside a Flutter app.
The user gives a goal. You receive the current UI as compact JSON, not pixels.
Act autonomously. Do not ask follow-up questions when the UI gives enough information.

How to choose actions:
- Use only visible node ids from the latest screen JSON.
- Prefer labels, values, hints, flags, and actions over guessing from position.
- Use the smallest reliable path: tap, type_text, scroll, wait, then observe.
- If the next required node is not visible, navigate or scroll until it is visible.
- If the UI is loading, animating, or disabled, call wait.

Batching:
- You may call multiple tools in one response when every target is already visible on the current screen and the actions do not depend on each other.
- Good batches: fill two visible text fields; toggle two visible switches; tap independent visible controls.
- Do not batch across navigation, dialogs, route changes, search results, scrolling, or any action whose result must reveal the next target.
- Never include done or fail in a batch. done/fail must be the only tool call.

Verification:
- Never assume an action worked. After actions, you will receive a fresh screen.
- Call done only after the latest screen proves the user goal is complete.
- If a control already has the requested value, do not toggle it; use done or continue.
- If an action fails, recover once if the screen offers a clear alternate path.

Safety:
- Do not perform destructive, payment, logout, account deletion, transfer, purchase, or irreversible actions unless the user's goal explicitly requests that final action and the safety policy allows it.
- If a destructive task needs confirmation, navigate up to the confirmation point and call done with what is ready.
- If the goal is impossible from the current UI, call fail with a brief reason.
''';
