import 'package:flutter_copilot/flutter_copilot.dart';

String describeEvent(CopilotEvent event) {
  return switch (event) {
    CopilotStarted(:final goal) => 'Started: $goal',
    CopilotSceneCaptured(:final scene) =>
      'Captured ${scene.nodes.length} nodes',
    CopilotLlmRequestStarted(:final step) => 'LLM request started: step $step',
    CopilotLlmRequestSucceeded(:final step) =>
      'LLM request succeeded: step $step',
    CopilotLlmRequestFailed(:final step, :final message) =>
      'LLM request failed: step $step: $message',
    CopilotActionPlanned(:final action) => 'Planned ${describeAction(action)}',
    CopilotActionExecuted(:final action, :final result) =>
      '${result.success ? 'Ran' : 'Failed'} ${describeAction(action)}: ${result.message}',
    CopilotFinished(:final message) => 'Finished: $message',
  };
}

String describeAction(CopilotAction action) {
  return switch (action) {
    TapAction(:final id) => 'tap $id',
    TypeTextAction(:final id) => 'type_text $id',
    ScrollAction(:final id, :final direction) => 'scroll $id $direction',
    WaitAction(:final duration) => 'wait ${duration.inMilliseconds}ms',
    DoneAction() => 'done',
    FailAction() => 'fail',
    UnknownAction(:final name) => name,
  };
}

String describeResult(CopilotRunResult result) {
  return switch (result) {
    CopilotCompleted(:final summary) => summary,
    CopilotFailed(:final reason) => 'Failed: $reason',
    CopilotCancelled() => 'Cancelled',
    CopilotMaxStepsExceeded(:final steps) => 'Stopped after $steps steps',
  };
}
