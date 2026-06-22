import '../actions/action_result.dart';
import '../actions/copilot_action.dart';
import '../scene/scene_graph.dart';

/// Event emitted during a copilot run.
sealed class CopilotEvent {
  /// Creates a copilot event.
  const CopilotEvent();
}

/// Emitted when a run starts.
class CopilotStarted extends CopilotEvent {
  /// Creates a start event.
  const CopilotStarted(this.goal);

  /// User goal for the run.
  final String goal;
}

/// Emitted after the UI scene is captured.
class CopilotSceneCaptured extends CopilotEvent {
  /// Creates a scene-captured event.
  const CopilotSceneCaptured(this.scene);

  /// Captured scene graph.
  final SceneGraph scene;
}

/// Emitted before an LLM request.
class CopilotLlmRequestStarted extends CopilotEvent {
  /// Creates an LLM request start event.
  const CopilotLlmRequestStarted(this.step);

  /// One-based step number.
  final int step;
}

/// Emitted after an LLM request succeeds.
class CopilotLlmRequestSucceeded extends CopilotEvent {
  /// Creates an LLM request success event.
  const CopilotLlmRequestSucceeded(this.step);

  /// One-based step number.
  final int step;
}

/// Emitted after an LLM request fails.
class CopilotLlmRequestFailed extends CopilotEvent {
  /// Creates an LLM request failure event.
  const CopilotLlmRequestFailed(this.step, this.message);

  /// One-based step number.
  final int step;

  /// Failure message.
  final String message;
}

/// Emitted when the model selects an action.
class CopilotActionPlanned extends CopilotEvent {
  /// Creates an action-planned event.
  const CopilotActionPlanned(this.action);

  /// Planned action.
  final CopilotAction action;
}

/// Emitted after an action executes.
class CopilotActionExecuted extends CopilotEvent {
  /// Creates an action-executed event.
  const CopilotActionExecuted(this.action, this.result);

  /// Executed action.
  final CopilotAction action;

  /// Execution result.
  final ActionResult result;
}

/// Emitted when a run finishes.
class CopilotFinished extends CopilotEvent {
  /// Creates a finish event.
  const CopilotFinished(this.message);

  /// Finish message.
  final String message;
}
