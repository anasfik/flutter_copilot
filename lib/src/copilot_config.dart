import 'llm/llm_adapter.dart';
import 'logging/copilot_event.dart';
import 'safety/copilot_safety_policy.dart';

/// Configuration for [CopilotApp] and each copilot run.
class CopilotConfig {
  /// Creates a copilot configuration.
  CopilotConfig({
    required this.llm,
    this.maxSteps = 12,
    this.settleDelay = const Duration(milliseconds: 300),
    CopilotSafetyPolicy? safetyPolicy,
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

  /// Optional event callback for logging or UI progress.
  final void Function(CopilotEvent event)? onEvent;

  /// Prints copilot events with [debugPrint] when true.
  final bool debugLogging;
}
