import '../actions/copilot_action.dart';
import '../scene/scene_graph.dart';
import '../scene/scene_node.dart';

/// Result of evaluating a planned action against a safety policy.
class CopilotSafetyDecision {
  /// Allows the action.
  const CopilotSafetyDecision.allow()
      : allowed = true,
        reason = null;

  /// Blocks the action with [reason].
  const CopilotSafetyDecision.block(this.reason) : allowed = false;

  /// Whether the action may execute.
  final bool allowed;

  /// Optional block reason.
  final String? reason;
}

/// Label-based guardrail for risky UI actions.
class CopilotSafetyPolicy {
  /// Creates a safety policy.
  CopilotSafetyPolicy({
    Iterable<Pattern>? blockedLabels,
    this.allowDestructiveActions = false,
  }) : blockedLabels = List<Pattern>.unmodifiable(
          blockedLabels ??
              const <Pattern>[
                'delete account',
                'remove account',
                'logout',
                'log out',
                'pay',
                'confirm payment',
                'send money',
                'transfer',
                'purchase',
              ],
        );

  /// Label, value, or hint patterns that block matching controls.
  final List<Pattern> blockedLabels;

  /// Whether to bypass destructive-action blocking.
  final bool allowDestructiveActions;

  /// Default safety policy.
  static final CopilotSafetyPolicy defaults = CopilotSafetyPolicy();

  /// Evaluates [action] against [scene].
  CopilotSafetyDecision evaluate(CopilotAction action, SceneGraph scene) {
    if (allowDestructiveActions) {
      return const CopilotSafetyDecision.allow();
    }

    final id = switch (action) {
      TapAction(:final id) => id,
      TypeTextAction(:final id) => id,
      ScrollAction(:final id) => id,
      _ => null,
    };
    if (id == null) {
      return const CopilotSafetyDecision.allow();
    }

    final node = _findNode(scene, id);
    final text = '${node?.label ?? ''} ${node?.value ?? ''} ${node?.hint ?? ''}'
        .toLowerCase();
    for (final pattern in blockedLabels) {
      final matches = switch (pattern) {
        String() => text.contains(pattern.toLowerCase()),
        _ => pattern.allMatches(text).isNotEmpty,
      };
      if (matches) {
        return CopilotSafetyDecision.block(
            'Blocked potentially destructive action on "$text".');
      }
    }
    return const CopilotSafetyDecision.allow();
  }

  SceneNode? _findNode(SceneGraph scene, String id) {
    for (final node in scene.nodes) {
      if (node.id == id) {
        return node;
      }
    }
    return null;
  }
}
