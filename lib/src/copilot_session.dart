import 'dart:convert';

import 'package:flutter/widgets.dart' hide DismissAction, ScrollAction;

import 'actions/action_executor.dart';
import 'actions/action_result.dart';
import 'actions/copilot_action.dart';
import 'actions/custom_action.dart';
import 'analytics/copilot_metrics.dart';
import 'llm/llm_adapter.dart';
import 'llm/llm_message.dart';
import 'llm/llm_tool.dart';
import 'logging/copilot_event.dart';
import 'copilot_config.dart';
import 'copilot_run_result.dart';
import 'memory/memory_entry.dart';
import 'retry/retry_engine.dart';
import 'scene/scene_capture.dart';
import 'scene/scene_compressor.dart';
import 'scene/scene_enhancer.dart';
import 'scene/scene_graph.dart';
import 'scene/scene_node.dart';
import 'scene/screenshot_capture.dart';
import 'session/prompt_builder.dart';

/// One autonomous observe-plan-act run.
///
/// A session owns a single execution loop: it captures the current Flutter
/// UI via the semantics tree, sends it to an LLM, parses the returned tool
/// calls into [CopilotAction]s, executes them, and repeats until the goal
/// is met, fails, or the step limit is reached.
///
/// Sessions are created internally by [CopilotController.run] and should
/// not be instantiated directly in application code.
class CopilotSession {
  /// Creates a copilot session.
  ///
  /// [goal] is the natural-language objective. [config] provides the LLM
  /// adapter, safety policy, and runtime options. [emit] is the event
  /// sink used to broadcast lifecycle events. Optional overrides for
  /// [capture], [compressor], [executor], [screenshotCapture], and
  /// [enhancer] allow dependency injection for testing.
  CopilotSession({
    required this.goal,
    required this.config,
    required this.emit,
    SceneCapture? capture,
    SceneCompressor? compressor,
    ActionExecutor? executor,
    ScreenshotCapture? screenshotCapture,
    SceneEnhancer? enhancer,
  })  : _capture = capture ?? SceneCapture(),
        _compressor = compressor ?? const SceneCompressor(),
        _executor = executor ?? ActionExecutor(capture: capture),
        _screenshotCapture = screenshotCapture ?? ScreenshotCapture(),
        _enhancer = enhancer ?? const SceneEnhancer();

  /// User goal for this run.
  final String goal;

  /// Runtime configuration.
  final CopilotConfig config;

  /// Event sink used by the session.
  final void Function(CopilotEvent event) emit;
  final SceneCapture _capture;
  final SceneCompressor _compressor;
  final ActionExecutor _executor;
  final ScreenshotCapture _screenshotCapture;
  final SceneEnhancer _enhancer;

  /// Runs the session to a terminal result.
  Future<CopilotRunResult> run() async {
    final startTime = DateTime.now();
    var steps = 0;
    var executedActions = 0;
    emit(CopilotStarted(goal));

    final builder = const PromptBuilder();
    final messages = <LlmMessage>[builder.buildSystemPrompt()];

    final memoryStore = config.memoryStore;
    if (memoryStore != null) {
      final memories = await memoryStore.getRecent(
        limit: config.memoryContextLimit,
      );
      if (memories.isNotEmpty) {
        messages.add(builder.buildMemoryMessage(memories));
      }
    }

    messages.add(builder.buildGoalMessage(goal));

    final actionResults = <Map<String, Object?>>[];
    final toolDefinitions = _mergedToolDefinitions();

    for (var step = 0; step < config.maxSteps; step++) {
      steps++;
      final scene = _observe();
      emit(CopilotSceneCaptured(scene));

      String sceneJson;
      if (config.enableScreenshots) {
        final screenshotBase64 = await _screenshotCapture.captureAsBase64();
        final shouldAttachScreenshot =
            !config.screenshotAsFallback || scene.nodes.length < 5;
        sceneJson = jsonEncode(
          _enhancer.enhanceSceneWithScreenshot(
            scene,
            base64Screenshot: shouldAttachScreenshot ? screenshotBase64 : null,
          ),
        );
      } else {
        sceneJson = scene.toCompactJson();
      }
      messages.add(builder.buildSceneMessage(sceneJson));

      final LlmResponse response;
      emit(CopilotLlmRequestStarted(step + 1));
      try {
        final retryConfig = config.retryConfig;
        if (retryConfig != null) {
          final retry = RetryEngine(retryConfig);
          response = await retry.run(
            () => config.llm.complete(messages: messages, tools: toolDefinitions),
          );
        } else {
          response = await config.llm
              .complete(messages: messages, tools: toolDefinitions);
        }
      } catch (error) {
        final reason = 'LLM request failed: $error';
        emit(CopilotLlmRequestFailed(step + 1, reason));
        return _finish(reason,
            startTime: startTime, steps: steps, executedActions: executedActions);
      }
      emit(CopilotLlmRequestSucceeded(step + 1));

      final toolCalls = response.allToolCalls;
      if (toolCalls.isEmpty) {
        return _finish(
          'Model did not call a tool: ${response.content}',
          startTime: startTime,
          steps: steps,
          executedActions: executedActions,
        );
      }

      var latestScene = scene;

      final parsedCalls = <MapEntry<LlmToolCall, CopilotAction>>[];
      for (final toolCall in toolCalls) {
        CopilotAction action;
        try {
          action =
              CopilotAction.fromToolCall(toolCall.name, toolCall.arguments);
        } catch (error) {
          if (config.customActions[toolCall.name] == null) {
            return _finish(
              'Model returned an invalid tool call: $error',
              startTime: startTime,
              steps: steps,
              executedActions: executedActions,
              actions: actionResults,
            );
          }
          // A registered custom tool owns its argument shape; the built-in
          // parser does not apply to it.
          action = UnknownAction(toolCall.name, toolCall.arguments);
        }
        parsedCalls.add(MapEntry(toolCall, action));
        emit(CopilotActionPlanned(action));
      }

      // Custom-first dispatch (custom action registry): a tool call whose
      // name is registered runs through the app's handler with its raw
      // arguments; only names without a handler fall through to the built-in
      // pipeline. For the terminal names, a registered handler is consulted
      // before the run ends: `done` completes the run only when the handler
      // reports success (the app verified the goal against fresh state), a
      // recoverable `done` failure feeds back to the model and the loop
      // continues, and `fail` ends the run with the handler's message.
      Future<CopilotRunResult?> runCustomCall(MapEntry<LlmToolCall, CopilotAction> entry) async {
        final call = entry.key;
        final handler = config.customActions[call.name]!;
        if (call.name == 'done' && toolCalls.length > 1) {
          return _finish(
            'done must be the only tool call in a response.',
            startTime: startTime,
            steps: steps,
            executedActions: executedActions,
            actions: actionResults,
          );
        }
        final action = CustomAction(name: call.name, args: call.arguments);
        final result = await handler.execute(action);
        emit(CopilotActionExecuted(UnknownAction(call.name, call.arguments), result));
        executedActions++;
        actionResults.add(<String, Object?>{
          'tool': call.name,
          'arguments': call.arguments,
          'result': result.toJson(),
        });
        if (call.name == 'done') {
          if (result.success) {
            emit(CopilotFinished(result.message));
            final collector = config.metricsCollector;
            if (collector != null) {
              collector.record(CopilotMetrics(
                goal: goal,
                startTime: startTime,
                endTime: DateTime.now(),
                steps: steps,
                actionsExecuted: executedActions,
                succeeded: true,
              ));
            }
            final store = config.memoryStore;
            if (store != null) {
              await store.add(MemoryEntry(
                goal: goal,
                result: result.message,
                timestamp: DateTime.now(),
              ));
            }
            return CopilotCompleted(result.message);
          }
          if (!result.recoverable) {
            return _finish(result.message,
                startTime: startTime,
                steps: steps,
                executedActions: executedActions,
                actions: actionResults);
          }
          // Not verified yet: keep the loop running on the fed-back result.
          return null;
        }
        if (call.name == 'fail') {
          return _finish(result.message,
              startTime: startTime,
              steps: steps,
              executedActions: executedActions,
              actions: actionResults);
        }
        if (!result.success && !result.recoverable) {
          return _finish(result.message,
              startTime: startTime,
              steps: steps,
              executedActions: executedActions,
              actions: actionResults);
        }
        return null;
      }

      for (final entry in parsedCalls) {
        final customHandler = config.customActions[entry.key.name];
        if (customHandler != null) {
          final terminal = await runCustomCall(entry);
          if (terminal != null) return terminal;
          continue;
        }
        switch (entry.value) {
          case DoneAction(:final summary):
            if (toolCalls.length > 1) {
              return _finish(
                'done must be the only tool call in a response.',
                startTime: startTime,
                steps: steps,
                executedActions: executedActions,
                actions: actionResults,
              );
            }
            emit(CopilotFinished(summary));
            final collector = config.metricsCollector;
            if (collector != null) {
              collector.record(CopilotMetrics(
                goal: goal,
                startTime: startTime,
                endTime: DateTime.now(),
                steps: steps,
                actionsExecuted: executedActions,
                succeeded: true,
              ));
            }
            final store = config.memoryStore;
            if (store != null) {
              await store.add(MemoryEntry(
                goal: goal,
                result: summary,
                timestamp: DateTime.now(),
              ));
            }
            return CopilotCompleted(summary);
          case FailAction(:final reason):
            if (toolCalls.length > 1) {
              return _finish(
                'fail must be the only tool call in a response.',
                startTime: startTime,
                steps: steps,
                executedActions: executedActions,
                actions: actionResults,
              );
            }
            return _finish(reason,
                startTime: startTime,
                steps: steps,
                executedActions: executedActions,
                actions: actionResults);
          case RequestConfirmationAction(:final reason):
            if (toolCalls.length > 1) {
              return _finish(
                'request_confirmation must be the only tool call in a response.',
                startTime: startTime,
                steps: steps,
                executedActions: executedActions,
                actions: actionResults,
              );
            }
            final approved = await _requestConfirmation(reason);
            actionResults.add(<String, Object?>{
              'tool': entry.key.name,
              'arguments': entry.key.arguments,
              'result': <String, Object?>{
                'success': approved,
                'message': approved
                    ? 'Confirmation approved.'
                    : 'Confirmation denied.',
                'recoverable': false,
              },
            });
            if (!approved) {
              emit(const CopilotFinished('Confirmation denied.'));
              final collector = config.metricsCollector;
              if (collector != null) {
                collector.record(CopilotMetrics(
                  goal: goal,
                  startTime: startTime,
                  endTime: DateTime.now(),
                  steps: steps,
                  actionsExecuted: executedActions,
                  succeeded: false,
                  failureReason: 'Confirmation denied.',
                ));
              }
              final store = config.memoryStore;
              if (store != null) {
                await store.add(MemoryEntry(
                  goal: goal,
                  result: 'Confirmation denied.',
                  timestamp: DateTime.now(),
                ));
              }
              return const CopilotCancelled();
            }
          default:
            break;
        }
      }

      var idx = 0;
      while (idx < parsedCalls.length) {
        final entry = parsedCalls[idx];

        // Custom-first dispatch: any call whose name is in the registry was
        // already executed through its handler in the pass above (including
        // the terminal `done`/`fail` handling). Skip it here — the built-in
        // pipeline must not run it a second time.
        if (config.customActions.containsKey(entry.key.name)) {
          idx++;
          continue;
        }

        if (entry.value is RequestConfirmationAction) {
          idx++;
          continue;
        }

        if (_isIndependent(entry.key)) {
          final batch = <MapEntry<LlmToolCall, CopilotAction>>[];
          while (idx < parsedCalls.length &&
              parsedCalls[idx].value is! RequestConfirmationAction &&
              _isIndependent(parsedCalls[idx].key)) {
            batch.add(parsedCalls[idx]);
            idx++;
          }

          for (final b in batch) {
            final safety =
                config.safetyPolicy.evaluate(b.value, latestScene);
            if (!safety.allowed) {
              final reason =
                  safety.reason ?? 'Action blocked by safety policy.';
              if (!safety.requiresConfirmation) {
                return _finish(reason,
                    startTime: startTime,
                    steps: steps,
                    executedActions: executedActions,
                    actions: actionResults);
              }
              if (config.accessMode != CopilotAccessMode.fullAccess) {
                final approved = await _requestConfirmation(
                  reason,
                  action: b.value,
                  scene: latestScene,
                );
                if (!approved) {
                  return _finish(reason,
                      startTime: startTime,
                      steps: steps,
                      executedActions: executedActions,
                      actions: actionResults);
                }
              }
            }
          }

          final results = await Future.wait(
            batch.map((b) async {
              final ActionResult actionResult;
              if (b.value is UnknownAction) {
                final handler = config.customActions[b.value.name];
                if (handler != null) {
                  actionResult = await handler
                      .execute(CustomAction.fromUnknown(b.value as UnknownAction));
                } else {
                  actionResult = await _executor.execute(b.value, latestScene);
                }
              } else {
                actionResult = await _executor.execute(b.value, latestScene);
              }
              return MapEntry(b, actionResult);
            }).toList(),
          );

          for (final result in results) {
            final action = result.key.value;
            final actionResult = result.value;
            emit(CopilotActionExecuted(action, actionResult));
            executedActions++;
            actionResults.add(<String, Object?>{
              'tool': result.key.key.name,
              'arguments': result.key.key.arguments,
              'result': actionResult.toJson(),
            });
            if (!actionResult.success && !actionResult.recoverable) {
              return _finish(actionResult.message,
                  startTime: startTime,
                  steps: steps,
                  executedActions: executedActions,
                  actions: actionResults);
            }
          }

          await _waitForUiSettle();
          latestScene = _observe();
        } else {
          final action = entry.value;

          final safety =
              config.safetyPolicy.evaluate(action, latestScene);
          if (!safety.allowed) {
            final reason =
                safety.reason ?? 'Action blocked by safety policy.';
            if (!safety.requiresConfirmation) {
              return _finish(reason,
                  startTime: startTime,
                  steps: steps,
                  executedActions: executedActions,
                  actions: actionResults);
            }
            if (config.accessMode != CopilotAccessMode.fullAccess) {
              final approved = await _requestConfirmation(
                reason,
                action: action,
                scene: latestScene,
              );
              if (!approved) {
                return _finish(reason,
                    startTime: startTime,
                    steps: steps,
                    executedActions: executedActions,
                    actions: actionResults);
              }
            }
          }

          final ActionResult actionResult;
          if (action is UnknownAction) {
            final handler = config.customActions[action.name];
            if (handler != null) {
              actionResult =
                  await handler.execute(CustomAction.fromUnknown(action));
            } else {
              actionResult = await _executor.execute(action, latestScene);
            }
          } else {
            actionResult = await _executor.execute(action, latestScene);
          }
          emit(CopilotActionExecuted(action, actionResult));
          executedActions++;
          actionResults.add(<String, Object?>{
            'tool': entry.key.name,
            'arguments': entry.key.arguments,
            'result': actionResult.toJson(),
          });
          if (!actionResult.success && !actionResult.recoverable) {
            return _finish(actionResult.message,
                startTime: startTime,
                steps: steps,
                executedActions: executedActions,
                actions: actionResults);
          }

          await _waitForUiSettle();
          latestScene = _observe();
          idx++;
        }
      }

      messages.addAll(builder.buildActionResultMessages(actionResults));
    }

    await _finish(
      'Maximum step count exceeded.',
      startTime: startTime,
      steps: steps,
      executedActions: executedActions,
      actions: actionResults,
    );
    return CopilotMaxStepsExceeded(config.maxSteps);
  }

  Future<CopilotFailed> _finish(
    String reason, {
    required DateTime startTime,
    required int steps,
    required int executedActions,
    bool succeeded = false,
    List<Map<String, Object?>> actions = const [],
  }) async {
    emit(CopilotFinished(reason));
    final collector = config.metricsCollector;
    if (collector != null) {
      collector.record(CopilotMetrics(
        goal: goal,
        startTime: startTime,
        endTime: DateTime.now(),
        steps: steps,
        actionsExecuted: executedActions,
        succeeded: succeeded,
        failureReason: succeeded ? null : reason,
      ));
    }
    final store = config.memoryStore;
    if (store != null) {
      await store.add(MemoryEntry(
        goal: goal,
        result: reason,
        timestamp: DateTime.now(),
      ));
    }
    return CopilotFailed(reason);
  }

  SceneGraph _observe() => _compressor.compress(_capture.capture());

  /// The LLM tool definitions for this run: the built-in vocabulary plus
  /// [CopilotConfig.customActionTools] (custom action registry). A custom
  /// descriptor named like a built-in tool overrides that built-in
  /// definition; the built-in set itself is never modified.
  List<LlmTool> _mergedToolDefinitions() {
    final custom = config.customActionTools;
    if (custom.isEmpty) return copilotTools;
    return <LlmTool>[
      for (final tool in copilotTools)
        if (custom.every((c) => c.name != tool.name)) tool,
      ...custom,
    ];
  }

  Future<bool> _requestConfirmation(
    String reason, {
    CopilotAction? action,
    SceneGraph? scene,
  }) async {
    if (config.accessMode == CopilotAccessMode.fullAccess) {
      emit(CopilotConfirmationRequested(reason));
      emit(const CopilotConfirmationResolved(true));
      return true;
    }

    emit(CopilotConfirmationRequested(reason));
    final callback = config.onConfirmationRequest;
    if (callback == null) {
      emit(const CopilotConfirmationResolved(false));
      return false;
    }

    final approved = await callback(CopilotConfirmationRequest(
      goal: goal,
      reason: reason,
      action: action,
      node: action == null || scene == null ? null : _targetNode(action, scene),
    ));
    emit(CopilotConfirmationResolved(approved));
    return approved;
  }

  SceneNode? _targetNode(CopilotAction action, SceneGraph scene) {
    final id = action.targetId;
    if (id == null) {
      return null;
    }
    for (final node in scene.nodes) {
      if (node.id == id) {
        return node;
      }
    }
    return null;
  }

  static bool _isIndependent(LlmToolCall tc) {
    return switch (tc.name) {
      'type_text' || 'clear_text' || 'replace_text' || 'tap' => true,
      _ => false,
    };
  }

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
