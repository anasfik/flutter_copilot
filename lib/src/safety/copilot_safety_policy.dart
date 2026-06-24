import '../actions/copilot_action.dart';
import '../scene/scene_graph.dart';
import '../scene/scene_node.dart';

/// Result of evaluating a planned action against a safety policy.
class CopilotSafetyDecision {
  /// Allows the action.
  const CopilotSafetyDecision.allow()
      : allowed = true,
        reason = null,
        requiresConfirmation = false;

  /// Requires app/user confirmation before executing the action.
  const CopilotSafetyDecision.confirm(this.reason)
      : allowed = false,
        requiresConfirmation = true;

  /// Denies the action with [reason].
  const CopilotSafetyDecision.deny(this.reason)
      : allowed = false,
        requiresConfirmation = false;

  /// Blocks the action with [reason].
  const CopilotSafetyDecision.block(this.reason)
      : allowed = false,
        requiresConfirmation = true;

  /// Whether the action may execute.
  final bool allowed;

  /// Optional block reason.
  final String? reason;

  /// Whether approval can unblock this action.
  final bool requiresConfirmation;
}

/// Developer-controlled label-based guardrails for UI actions.
class CopilotSafetyPolicy {
  /// Creates a safety policy.
  CopilotSafetyPolicy({
    Iterable<Pattern>? blockedLabels,
    Iterable<Pattern>? deniedLabels,
    Iterable<Pattern>? doNotTouchLabels,
    Iterable<Pattern>? sensitiveLabels,
    Iterable<Pattern>? carefulLabels,
    this.allowDestructiveActions = false,
  })  : deniedLabels = List<Pattern>.unmodifiable(
          <Pattern>[
            ...?deniedLabels,
            ...?doNotTouchLabels,
          ],
        ),
        blockedLabels = List<Pattern>.unmodifiable(
          <Pattern>[
            ...?blockedLabels,
            if (blockedLabels == null) ...[
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
            ...?sensitiveLabels,
            ...?carefulLabels,
          ],
        );

  /// Label, value, or hint patterns that require confirmation.
  final List<Pattern> blockedLabels;

  /// Label, value, or hint patterns that are always denied.
  final List<Pattern> deniedLabels;

  /// Whether to bypass confirmation for destructive/sensitive actions.
  ///
  /// Always-denied labels still remain denied.
  final bool allowDestructiveActions;

  /// Default safety policy.
  static final CopilotSafetyPolicy defaults = CopilotSafetyPolicy();

  /// Evaluates [action] against [scene].
  CopilotSafetyDecision evaluate(CopilotAction action, SceneGraph scene) {
    final id = action.targetId;
    if (id == null) {
      return const CopilotSafetyDecision.allow();
    }

    final node = _findNode(scene, id);
    final text = '${node?.label ?? ''} ${node?.value ?? ''} ${node?.hint ?? ''}'
        .toLowerCase();

    final deniedMatch = _matchingPattern(deniedLabels, text);
    if (deniedMatch != null) {
      return CopilotSafetyDecision.deny(
          'Denied by developer safety policy on "$text" matching "$deniedMatch".');
    }

    if (allowDestructiveActions) {
      return const CopilotSafetyDecision.allow();
    }

    final confirmationMatch = _matchingPattern(blockedLabels, text);
    if (confirmationMatch != null) {
      return CopilotSafetyDecision.confirm(
          'Approval required by developer safety policy on "$text" matching "$confirmationMatch".');
    }
    return const CopilotSafetyDecision.allow();
  }

  Pattern? _matchingPattern(List<Pattern> patterns, String text) {
    for (final pattern in patterns) {
      final matches = switch (pattern) {
        String() => text.contains(pattern.toLowerCase()),
        _ => pattern.allMatches(text).isNotEmpty,
      };
      if (matches) {
        return pattern;
      }
    }
    return null;
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
