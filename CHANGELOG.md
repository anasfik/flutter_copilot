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
