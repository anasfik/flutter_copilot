## 0.13.0

- Added `CopilotConfig.customActionTools` — custom tool descriptors merged into the LLM tool definitions. Without this, registered `customActions` were invisible to the model, which only ever saw the 18 built-in tools.
- Custom-first dispatch: a tool call whose name is registered in `customActions` now runs through the handler with its raw arguments in every execution path (including batched calls); the handler owns the argument shape, so non-built-in-shaped arguments no longer abort the run as "invalid tool call".
- Terminal semantics for registered `done`/`fail` handlers: `done` completes the run only when the handler reports success (a `recoverable: true` failure feeds back to the model and the loop continues); `fail` ends the run with the handler's message.
- A custom descriptor named like a built-in tool overrides that built-in definition; the built-in set itself is never modified.
- Fixed a double-execution bug: the second execution pass re-ran tool calls that a registered handler had already executed (a custom tool could run twice per response). The pass now skips every call whose name has a registered handler.

## 0.12.0

- Added retry/recovery engine with configurable exponential backoff for transient LLM failures.
- Added custom tools extension API — register `CustomActionHandler` implementations for developer-defined actions.
- Added analytics/metrics collection with `CopilotMetrics` and `MetricsCollector` for success rates, duration, and step counts.
- Added conversation memory engine with `MemoryStore` interface and `InMemoryStore` for multi-turn context.
- Added parallel action execution — independent batched actions run concurrently via `Future.wait`.
- Added optional screenshot fallback for widgets with poor semantics.
- Added `@immutable` annotations to all immutable classes.
- Added dartdoc comments to all public APIs with code examples.
- Added Limitations, Performance, and Migration Guide sections to README.
- Refactored `CopilotSession` — extracted `PromptBuilder`, DRY terminal states with `_finish()` helper.
- Fixed hardcoded pointer IDs in `ActionExecutor` — now uses auto-incrementing counter.
- Fixed missing exports for `CustomAction` and `CustomActionHandler`.

## 0.11.0

- Expanded action set to 18 types: tap, long_press, type_text, clear_text, replace_text, set_text_selection, keyboard_action, scroll, drag, long_press_drag, slider_to_value, adjust_value, dismiss, system_back, request_confirmation, wait, done, fail.
- Added action batching — model can call multiple independent tools in one response.
- Added `CopilotAccessMode` with `fullAccess` and `askBeforeSensitiveActions`.
- Added `CopilotConfirmationRequest` and `CopilotConfirmationCallback` for user approval flows.
- Improved safety policy with custom `blockedLabels` patterns (String and RegExp).
- Added `CopilotRunResult` sealed types: `CopilotCompleted`, `CopilotFailed`, `CopilotCancelled`, `CopilotMaxStepsExceeded`.
- Rewrote README with full architecture docs, badges, API reference, and use cases.
- Fixed `FlagsCollection` analysis for Flutter 3.44.2 compatibility.
- Redesigned example app with interactive font scale, add task dialog, commerce demo semantics, profile save feedback, and copilot panel auto-scroll.

## 0.10.0

- Added explicit platform support for Android, iOS, Linux, macOS, Windows, and Web.
- Redesigned example app with polished Material 3 UI and improved UX.
- Added proper state management with `AppState` and `AppStateScope`.
- Added themed components: `CopilotPanel`, `PromptInput`, `StatCard`, `SectionHeader`.
- Improved accessibility semantics for copilot actions.
- Updated dependencies.

## 0.9.1

- Initial MVP package.
- Added `CopilotApp`, `CopilotController`, and `CopilotSession`.
- Added semantics scene capture and compression.
- Added provider-agnostic LLM adapter interface.
- Added fake and OpenAI LLM adapters.
- Added UI action executor for tap, text input, scroll, and wait.
- Added default safety policy for destructive labels.
- Added example app and focused tests.
