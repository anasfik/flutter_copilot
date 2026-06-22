/// Result of executing a UI action.
class ActionResult {
  const ActionResult._({
    required this.success,
    required this.message,
    this.recoverable = true,
  });

  /// Whether the action executed successfully.
  final bool success;

  /// Human-readable execution message.
  final String message;

  /// Whether the model can try to recover after this failure.
  final bool recoverable;

  /// Creates a successful action result.
  factory ActionResult.success(String message) {
    return ActionResult._(success: true, message: message);
  }

  /// Creates a failed action result.
  factory ActionResult.failure(String message, {bool recoverable = true}) {
    return ActionResult._(
        success: false, message: message, recoverable: recoverable);
  }

  /// Converts the result to JSON for model feedback.
  Map<String, Object?> toJson() => <String, Object?>{
        'success': success,
        'message': message,
        'recoverable': recoverable,
      };
}
