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
