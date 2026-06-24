import 'llm/llm_adapter.dart';
import 'logging/copilot_event.dart';
import 'safety/copilot_safety_policy.dart';
import 'actions/copilot_action.dart';
import 'scene/scene_node.dart';

/// How much autonomy the copilot has for sensitive actions.
enum CopilotAccessMode {
  /// Allow sensitive actions without asking.
  fullAccess,

  /// Ask before continuing on sensitive or risky actions.
  askBeforeSensitiveActions,
}

/// Request passed to the app when the copilot needs approval.
class CopilotConfirmationRequest {
  /// Creates a confirmation request.
  const CopilotConfirmationRequest({
    required this.goal,
    required this.reason,
    this.action,
    this.node,
  });

  /// User goal for the current run.
  final String goal;

  /// Why approval is needed.
  final String reason;

  /// Planned action that needs approval, when there is one.
  final CopilotAction? action;

  /// Target scene node for [action], when available.
  final SceneNode? node;
}

/// Called when the copilot needs approval to continue.
typedef CopilotConfirmationCallback = Future<bool> Function(
    CopilotConfirmationRequest request);

/// Configuration for [CopilotApp] and each copilot run.
class CopilotConfig {
  /// Creates a copilot configuration.
  CopilotConfig({
    required this.llm,
    this.maxSteps = 12,
    this.settleDelay = const Duration(milliseconds: 300),
    CopilotSafetyPolicy? safetyPolicy,
    this.accessMode = CopilotAccessMode.askBeforeSensitiveActions,
    this.onConfirmationRequest,
    this.onEvent,
    this.debugLogging = false,
  }) : safetyPolicy = safetyPolicy ?? CopilotSafetyPolicy.defaults;

  /// Model adapter used to plan UI actions.
  final LlmAdapter llm;

  /// Maximum observe-plan-act cycles before the run stops.
  final int maxSteps;

  /// Delay after actions so Flutter can rebuild and settle animations.
  final Duration settleDelay;

  /// Guardrail checked before executing UI actions.
  final CopilotSafetyPolicy safetyPolicy;

  /// Whether sensitive actions require app approval.
  final CopilotAccessMode accessMode;

  /// Called before continuing with sensitive actions.
  final CopilotConfirmationCallback? onConfirmationRequest;

  /// Optional event callback for logging or UI progress.
  final void Function(CopilotEvent event)? onEvent;

  /// Prints copilot events with [debugPrint] when true.
  final bool debugLogging;
}
