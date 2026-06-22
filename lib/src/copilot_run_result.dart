/// Result returned by [CopilotController.run].
sealed class CopilotRunResult {
  /// Creates a run result.
  const CopilotRunResult();
}

/// The goal was completed.
class CopilotCompleted extends CopilotRunResult {
  /// Creates a completed result with a human-readable [summary].
  const CopilotCompleted(this.summary);

  /// Summary returned by the model.
  final String summary;
}

/// The run stopped because it could not continue.
class CopilotFailed extends CopilotRunResult {
  /// Creates a failed result with a [reason].
  const CopilotFailed(this.reason);

  /// Reason the run failed.
  final String reason;
}

/// The run was cancelled.
class CopilotCancelled extends CopilotRunResult {
  /// Creates a cancelled result.
  const CopilotCancelled();
}

/// The run reached the configured maximum step count.
class CopilotMaxStepsExceeded extends CopilotRunResult {
  /// Creates a max-steps result.
  const CopilotMaxStepsExceeded(this.steps);

  /// Number of steps attempted.
  final int steps;
}
