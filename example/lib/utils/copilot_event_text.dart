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
    CopilotConfirmationRequested(:final reason) =>
      'Confirmation requested: $reason',
    CopilotConfirmationResolved(:final approved) =>
      'Confirmation ${approved ? 'approved' : 'denied'}',
    CopilotFinished(:final message) => 'Finished: $message',
  };
}

String describeAction(CopilotAction action) {
  return switch (action) {
    TapAction(:final id) => 'tap $id',
    LongPressAction(:final id) => 'long_press $id',
    TypeTextAction(:final id) => 'type_text $id',
    ClearTextAction(:final id) => 'clear_text $id',
    ReplaceTextAction(:final id) => 'replace_text $id',
    SetTextSelectionAction(:final id, :final start, :final end) =>
      'set_text_selection $id $start:$end',
    KeyboardAction(:final key) => 'keyboard_action $key',
    ScrollAction(:final id, :final direction) => 'scroll $id $direction',
    DragAction(:final id, :final direction) => 'drag $id $direction',
    LongPressDragAction(:final id, :final direction) =>
      'long_press_drag $id $direction',
    SliderToValueAction(:final id, :final value) =>
      'slider_to_value $id $value',
    AdjustValueAction(:final id, :final direction) =>
      'adjust_value $id $direction',
    DismissAction(:final id) => 'dismiss $id',
    SystemBackAction() => 'system_back',
    RequestConfirmationAction(:final reason) => 'request_confirmation $reason',
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
