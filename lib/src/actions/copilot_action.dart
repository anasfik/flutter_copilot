/// Action selected by the model.
sealed class CopilotAction {
  /// Creates a copilot action.
  const CopilotAction();

  /// Parses an action from an LLM tool call.
  factory CopilotAction.fromToolCall(String name, Map<String, Object?> args) {
    final normalized = name.trim();
    return switch (normalized) {
      'tap' => TapAction(_requiredString(args, 'id')),
      'type_text' => TypeTextAction(
          _requiredString(args, 'id'), _requiredString(args, 'text')),
      'scroll' => ScrollAction(
          _requiredString(args, 'id'),
          _requiredString(args, 'direction'),
          (args['amount'] as String?) ?? 'medium',
        ),
      'wait' => WaitAction(Duration(
          milliseconds: (args['duration_ms'] as num?)?.round() ?? 300)),
      'done' => DoneAction(_requiredString(args, 'summary')),
      'fail' => FailAction(_requiredString(args, 'reason')),
      _ => UnknownAction(normalized, args),
    };
  }

  /// Tool name for this action.
  String get name;
}

/// Taps a visible semantics node.
class TapAction extends CopilotAction {
  /// Creates a tap action.
  const TapAction(this.id);

  /// Public scene node id.
  final String id;
  @override
  String get name => 'tap';
}

/// Types text into a visible text field node.
class TypeTextAction extends CopilotAction {
  /// Creates a text input action.
  const TypeTextAction(this.id, this.text);

  /// Public scene node id.
  final String id;

  /// Text to enter.
  final String text;
  @override
  String get name => 'type_text';
}

/// Scrolls a visible scrollable node.
class ScrollAction extends CopilotAction {
  /// Creates a scroll action.
  const ScrollAction(this.id, this.direction, this.amount);

  /// Public scene node id.
  final String id;

  /// Scroll direction.
  final String direction;

  /// Scroll amount.
  final String amount;
  @override
  String get name => 'scroll';
}

/// Waits for loading or animation.
class WaitAction extends CopilotAction {
  /// Creates a wait action.
  const WaitAction(this.duration);

  /// Time to wait.
  final Duration duration;
  @override
  String get name => 'wait';
}

/// Marks the goal complete.
class DoneAction extends CopilotAction {
  /// Creates a done action.
  const DoneAction(this.summary);

  /// Completion summary.
  final String summary;
  @override
  String get name => 'done';
}

/// Marks the goal impossible.
class FailAction extends CopilotAction {
  /// Creates a fail action.
  const FailAction(this.reason);

  /// Failure reason.
  final String reason;
  @override
  String get name => 'fail';
}

/// Represents an unsupported model tool call.
class UnknownAction extends CopilotAction {
  /// Creates an unknown action.
  const UnknownAction(this.name, this.args);

  /// Unsupported tool name.
  @override
  final String name;

  /// Raw tool arguments.
  final Map<String, Object?> args;
}

String _requiredString(Map<String, Object?> args, String key) {
  final value = args[key];
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  throw ArgumentError.value(value, key, 'Expected a non-empty string');
}
