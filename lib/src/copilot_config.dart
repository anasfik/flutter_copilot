import 'actions/custom_action_handler.dart';
import 'analytics/metrics_collector.dart';
import 'llm/llm_adapter.dart';
import 'llm/llm_tool.dart';
import 'logging/copilot_event.dart';
import 'memory/memory_store.dart';
import 'retry/retry_config.dart';
import 'safety/copilot_safety_policy.dart';
import 'actions/copilot_action.dart';
import 'scene/scene_node.dart';

/// How much autonomy the copilot has for sensitive actions.
enum CopilotAccessMode {
  /// Allow sensitive actions without asking.
  ///
  /// The copilot executes destructive, payment, or account-related actions
  /// directly, relying solely on the [CopilotSafetyPolicy] guardrails.
  fullAccess,

  /// Ask before continuing on sensitive or risky actions.
  ///
  /// The copilot pauses and invokes [CopilotConfig.onConfirmationRequest]
  /// whenever the safety policy flags an action as requiring confirmation.
  askBeforeSensitiveActions,
}

/// Request passed to the app when the copilot needs approval.
///
/// Contains enough context for the app to present a meaningful confirmation
/// dialog to the user, including the goal, reason, planned action, and the
/// target scene node when available.
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
///
/// Return `true` to approve the action, or `false` to deny it and abort
/// the run. The [request] contains the goal, reason, and optional action
/// details so the app can present an informed dialog.
typedef CopilotConfirmationCallback = Future<bool> Function(
    CopilotConfirmationRequest request);

/// Configuration for [CopilotApp] and each copilot run.
///
/// At minimum, supply an [LlmAdapter] via [llm]. All other parameters
/// have sensible defaults.
///
/// ```dart
/// final config = CopilotConfig(
///   llm: OpenAILlmAdapter(apiKey: 'sk-...'),
///   maxSteps: 8,
///   accessMode: CopilotAccessMode.askBeforeSensitiveActions,
///   onConfirmationRequest: (request) async {
///     return await showConfirmationDialog(request.goal, request.reason);
///   },
///   debugLogging: true,
/// );
///
/// await CopilotApp(
///   config: config,
///   child: MyApp(),
/// );
/// ```
class CopilotConfig {
  /// Creates a copilot configuration.
  CopilotConfig({
    required this.llm,
    this.maxSteps = 12,
    this.settleDelay = const Duration(milliseconds: 300),
    this.retryConfig,
    CopilotSafetyPolicy? safetyPolicy,
    this.accessMode = CopilotAccessMode.askBeforeSensitiveActions,
    this.onConfirmationRequest,
    this.onEvent,
    this.debugLogging = false,
    this.metricsCollector,
    Map<String, CustomActionHandler>? customActions,
    List<LlmTool>? customActionTools,
    this.enableScreenshots = false,
    this.screenshotAsFallback = true,
    this.memoryStore,
    this.memoryContextLimit = 10,
  })  : safetyPolicy = safetyPolicy ?? CopilotSafetyPolicy.defaults,
        customActions = customActions ?? const <String, CustomActionHandler>{},
        customActionTools = customActionTools ?? const <LlmTool>[];

  /// Model adapter used to plan UI actions.
  final LlmAdapter llm;

  /// Maximum observe-plan-act cycles before the run stops.
  ///
  /// Each cycle captures the screen, sends it to the LLM, and executes the
  /// returned actions. Defaults to 12.
  final int maxSteps;

  /// Delay after actions so Flutter can rebuild and settle animations.
  ///
  /// The session waits this long after executing actions before re-capturing
  /// the scene, ensuring animations and rebuilds have finished.
  final Duration settleDelay;

  /// Optional retry configuration for transient LLM failures.
  ///
  /// When non-null, LLM requests that fail with transient errors are
  /// retried according to the backoff policy in [RetryConfig].
  final RetryConfig? retryConfig;

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

  /// Optional collector for recording run metrics.
  final MetricsCollector? metricsCollector;

  /// Map of tool names to custom action handlers.
  ///
  /// When the model emits a tool call whose name matches a key in this map,
  /// the corresponding [CustomActionHandler] executes instead of the default
  /// [ActionExecutor].
  final Map<String, CustomActionHandler> customActions;

  /// Action descriptors merged into the LLM tool definitions.
  ///
  /// The custom-action-registry hook: the app supplies the [LlmTool]
  /// descriptors of its registered [customActions] here, and they are
  /// appended to the built-in tool definitions on every model request —
  /// so the model knows the app's tools without forking the built-in
  /// action vocabulary. A descriptor with the same name as a built-in
  /// tool overrides that built-in definition (e.g. a stricter `done`
  /// schema), while the built-in set itself is never modified.
  ///
  /// Dispatch is custom-first: a tool call whose name is in [customActions]
  /// runs through that handler; unknown names fall through to the built-in
  /// pipeline. For the terminal names `done`/`fail`, a registered handler is
  /// consulted before the run ends: `done` completes the run only when the
  /// handler reports success (the app verified the goal), and `fail` ends
  /// the run with the handler's message.
  final List<LlmTool> customActionTools;

  /// Whether screenshot capture is enabled.
  ///
  /// When true, a screenshot is captured alongside the semantics tree and
  /// appended to the scene context sent to the LLM.
  final bool enableScreenshots;

  /// Whether to use screenshots as a fallback when semantics are insufficient.
  ///
  /// When true and [enableScreenshots] is true, the screenshot is only sent
  /// when the compressed scene has few interactive nodes.
  final bool screenshotAsFallback;

  /// Optional memory store for persisting session history.
  ///
  /// When non-null, each completed run is stored and recent entries are
  /// injected as context at the start of the next run.
  final MemoryStore? memoryStore;

  /// Maximum number of memory entries to load as context.
  ///
  /// Only the most recent [memoryContextLimit] entries are loaded from the
  /// [memoryStore] and included in the LLM prompt. Defaults to 10.
  final int memoryContextLimit;
}
