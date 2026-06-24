# flutter_copilot

**Turn your Flutter app into an AI-operable interface — no screenshots, no overlay chatbot, just natural-language goals becoming real UI actions, natively.**

[![pub.dev](https://img.shields.io/pub/v/flutter_copilot.svg?label=flutter_copilot&logo=dart&logoColor=white)](https://pub.dev/packages/flutter_copilot)
[![pub.dev points](https://img.shields.io/pub/points/flutter_copilot?logo=dart&logoColor=white&color=blue)](https://pub.dev/packages/flutter_copilot)
[![pub.dev likes](https://img.shields.io/pub/likes/flutter_copilot?logo=dart&logoColor=white&color=green)](https://pub.dev/packages/flutter_copilot)
[![GitHub stars](https://img.shields.io/github/stars/anasfik/flutter_copilot?logo=github&logoColor=white&color=orange)](https://github.com/anasfik/flutter_copilot)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.32.0-blue.svg?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart SDK](https://img.shields.io/badge/Dart-%3E%3D3.3.0-blue.svg?logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

## Demo

https://github.com/user-attachments/assets/7dcb8504-00b3-4f68-80d3-19f74df75417

Note: this is clearly vibe-coded to make the demo faster, don't wanna hear anyone opening an issue mentioning this please!

> **If you find flutter_copilot interesting or useful, please star the repo.** It helps others discover the project and encourages continued development. Every star counts.

---

`flutter_copilot` gives your Flutter app an invisible AI copilot that can understand the current screen, decide what to do next, and operate the UI on behalf of the user.

Instead of building yet another chatbot inside your app, you get real agentic behavior: the copilot inspects the visible Flutter UI, chooses actions, taps buttons, types into fields, scrolls lists, waits for changes, and continues until the goal is complete.

```dart
final controller = CopilotController.of(context);
final result = await controller.run(
  'Go to settings, turn on dark mode, enable weekly summary emails, and save.',
);
```

That single line can navigate multiple screens, toggle controls, fill forms, and confirm changes — all driven by the model through Flutter's own semantics tree.

---

## Table of Contents

- [Why flutter\_copilot](#why-flutter_copilot)
- [How It Works](#how-it-works)
- [Key Features](#key-features)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Supported Actions](#supported-actions)
- [Safety & Confirmation](#safety--confirmation)
- [Progress Events](#progress-events)
- [LLM Providers](#llm-providers)
- [Help the Copilot See Your UI](#help-the-copilot-see-your-ui)
- [Architecture](#architecture)
- [Use Cases](#use-cases)
- [Example App](#example-app)
- [Testing](#testing)
- [Contributing](#contributing)
- [License](#license)

---

## Why flutter_copilot

### Native to Flutter

`flutter_copilot` is designed specifically for Flutter apps. It works with Flutter's own UI and semantics system instead of depending on brittle screenshots, OCR, or external automation layers. The copilot understands the app through structured UI information, not by guessing pixels.

### No screenshots required

Many AI UI agents depend on screenshots and vision models. That can be slower, more expensive, less private, and less deterministic.

`flutter_copilot` works from the Flutter semantics tree, so the model sees a compact, structured representation of the current UI:

- **Lower token usage** than sending screenshots.
- **Better privacy** because screenshots never leave the device.
- **More deterministic** UI understanding.
- **Better compatibility** with accessibility-friendly apps.
- **Less dependence** on visual layout changes.

### No overlay chat UI required

The copilot runs invisibly inside your app. You do not need to redesign your product around a chatbot bubble. Trigger it from your own UI, voice input, support flow, onboarding flow, command palette, or any custom entry point.

### Natural-language app control

Users express goals naturally:

- *"Create a new task called Buy milk."*
- *"Find my last invoice."*
- *"Change my profile name."*
- *"Turn on dark mode."*
- *"Search for flights to Paris."*
- *"Delete the completed items."*
- *"Help me finish this form."*

The copilot translates the goal into UI actions.

### Works with the UI you already have

You do not need to rebuild your app around special AI screens. Wrap your app, provide a model adapter, and expose the current UI through Flutter semantics. The better your accessibility labels are, the better the copilot becomes.

### Accessibility improvements become AI improvements

Because `flutter_copilot` relies on semantics, improving accessibility also improves the AI agent's ability to understand the app. One improvement helps both screen reader users and AI-assisted navigation:

- Screen reader users.
- Voice control users.
- AI-assisted app navigation.
- Automated testing and QA.

### Safer than free-form code execution

The model does not need direct access to arbitrary app internals. It receives a controlled set of tools and can only perform actions the developer exposes. This makes it easier to build safety policies around sensitive flows such as payments, deletion, or account changes.

### Tool-based and inspectable

The copilot calls explicit tools — `tap`, `type_text`, `scroll`, `wait`, `done`, `fail` — not free-form code. That makes behavior easier to log, debug, replay, and evaluate. A developer can inspect what the model saw, what action it chose, why it stopped, and whether the action succeeded.

---

## How It Works

`flutter_copilot` runs an **observe → plan → act** loop:

```
┌─────────────────────────────────────────────────────────┐
│                     User Goal                           │
│   "Go to settings, turn on dark mode, and save."        │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│  1. OBSERVE  ─  Capture the Flutter semantics tree      │
│                  Compress to model-friendly JSON         │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│  2. PLAN     ─  Send scene JSON + goal to the LLM       │
│                  Model selects tool calls (actions)      │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│  3. ACT      ─  Execute actions via semantics or        │
│                  pointer events                         │
│                  Safety policy check before execution   │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
              ┌────────┴────────┐
              │  Goal complete? │
              └────────┬────────┘
                 yes   │   no
                  ◄────┘────►
              ┌────────┐  ┌──────────┐
              │  DONE  │  │ Re-observe│
              └────────┘  └──────────┘
```

Each cycle:

1. **Observe** — `SceneCapture` reads Flutter's live semantics tree and `SceneCompressor` reduces it to the most relevant nodes.
2. **Plan** — The compressed scene JSON and user goal are sent to the LLM. The model returns tool calls (actions).
3. **Act** — `ActionExecutor` performs the action using semantics actions when available, falling back to pointer events.
4. **Verify** — A fresh scene is captured. The loop continues until the model calls `done` or `fail`.

---

## Key Features

| Feature | Description |
|---|---|
| **Semantics-first** | Reads Flutter's semantics tree — no screenshots, no OCR, no vision models |
| **18 action types** | Tap, long press, type, clear, replace, scroll, drag, slider, dismiss, keyboard, and more |
| **Action batching** | Multiple independent actions in a single model step |
| **Safety policy** | Built-in guardrails block destructive actions (payments, deletion, logout) |
| **Confirmation flow** | Sensitive actions pause and ask the app/user before proceeding |
| **Event streaming** | Real-time progress events for UI feedback and logging |
| **Provider-agnostic** | Works with OpenAI and any OpenAI-compatible API |
| **Sealed result types** | `CopilotCompleted`, `CopilotFailed`, `CopilotCancelled`, `CopilotMaxStepsExceeded` |
| **Configurable autonomy** | `fullAccess` or `askBeforeSensitiveActions` mode |
| **Fake adapter for tests** | Deterministic `FakeLlmAdapter` for unit and widget tests |
| **Zero overlays** | No chatbot bubble, no injected UI — runs invisibly inside your app |
| **Cross-platform** | Android, iOS, Linux, macOS, Windows, and Web |

---

## Quick Start

### 1. Add the dependency

```yaml
dependencies:
  flutter_copilot: ^0.10.0
```

### 2. Wrap your app with `CopilotApp`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_copilot/flutter_copilot.dart';

void main() {
  runApp(
    CopilotApp(
      config: CopilotConfig(
        llm: OpenAILlmAdapter(
          apiKey: 'YOUR_API_KEY',
          model: 'gpt-4.1',
        ),
        debugLogging: true,
      ),
      child: const MyApp(),
    ),
  );
}
```

### 3. Run a goal from anywhere in your app

```dart
final controller = CopilotController.of(context);
final result = await controller.run(
  'Open profile, update display name to Alex, and save.',
);

switch (result) {
  case CopilotCompleted(:final summary):
    print('Done: $summary');
  case CopilotFailed(:final reason):
    print('Failed: $reason');
  case CopilotCancelled():
    print('Cancelled by user');
  case CopilotMaxStepsExceeded(:final steps):
    print('Stopped after $steps steps');
}
```

That's it. The copilot handles navigation, form filling, toggling controls, and confirmation — all from a single natural-language string.

---

## Configuration

```dart
CopilotConfig(
  // Required: the LLM adapter to use
  llm: OpenAILlmAdapter(apiKey: '...', model: 'gpt-4.1'),

  // Maximum observe→plan→act cycles before stopping (default: 12)
  maxSteps: 12,

  // Delay after actions so Flutter can rebuild and settle (default: 300ms)
  settleDelay: Duration(milliseconds: 300),

  // Developer-owned rules for denied and approval-gated UI targets
  safetyPolicy: CopilotSafetyPolicy.defaults,

  // Autonomy level: fullAccess or askBeforeSensitiveActions (default)
  accessMode: CopilotAccessMode.askBeforeSensitiveActions,

  // Callback when the copilot needs approval to continue
  onConfirmationRequest: (request) async {
    return await showConfirmDialog(request.goal, request.reason);
  },

  // Optional event callback for logging or UI progress
  onEvent: (event) => print(event),

  // Print copilot events with debugPrint (default: false)
  debugLogging: true,
)
```

---

## Supported Actions

The copilot can perform **18 distinct action types** against the Flutter UI:

| Action | Tool Name | Description |
|---|---|---|
| Tap | `tap` | Tap a visible UI node by id |
| Long Press | `long_press` | Long-press a visible node (context menus, drag handles) |
| Type Text | `type_text` | Enter text into a text field |
| Clear Text | `clear_text` | Clear all text from a text field |
| Replace Text | `replace_text` | Replace all text in a text field |
| Set Text Selection | `set_text_selection` | Set cursor/selection range in a text field |
| Keyboard Action | `keyboard_action` | Send keyboard events (enter, tab, escape, backspace, etc.) |
| Scroll | `scroll` | Scroll a scrollable area in any direction |
| Drag | `drag` | Drag across a node (swipe buttons, carousels, maps) |
| Long Press Drag | `long_press_drag` | Hold then drag (reorder handles, drag handles) |
| Slider to Value | `slider_to_value` | Drag a slider to a normalized 0.0–1.0 value |
| Adjust Value | `adjust_value` | Semantic increase/decrease on steppers and sliders |
| Dismiss | `dismiss` | Dismiss a dismissible node (semantic or drag fallback) |
| System Back | `system_back` | Navigate back when no text field is focused |
| Wait | `wait` | Wait for loading, animation, or async UI state |
| Request Confirmation | `request_confirmation` | Ask the app/user before a sensitive step |
| Done | `done` | Mark the goal as complete |
| Fail | `fail` | Stop when the goal cannot be completed |

### Action Batching

The model can batch multiple independent actions in a single response when all targets are visible on the current screen and the actions do not depend on each other:

```dart
// Model can batch these — both fields are visible, no navigation needed
// tool_calls: [type_text("email_field", "alex@example.com"), type_text("name_field", "Alex")]
```

Batching is not used across navigation, dialogs, scrolling, or any action whose result must reveal the next target. `done` and `fail` are never batched.

---

## Safety & Confirmation

### Safety Policy

`flutter_copilot` is developer-controlled by design. You decide which UI targets are never touched and which targets need approval before the copilot continues.

The default policy treats common destructive/payment/account controls as approval-gated:

```dart
CopilotSafetyPolicy(
  blockedLabels: <Pattern>[
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
)
```

When a planned action matches `blockedLabels`, `sensitiveLabels`, or `carefulLabels`, the copilot asks for approval in `CopilotAccessMode.askBeforeSensitiveActions`. In `CopilotAccessMode.fullAccess`, approval-gated labels are allowed.

Labels in `deniedLabels` or `doNotTouchLabels` are always denied, even in full access.

### Custom Safety Policies

```dart
CopilotConfig(
  safetyPolicy: CopilotSafetyPolicy(
    // Always denied. The copilot must not touch these.
    doNotTouchLabels: <Pattern>[
      'production billing',
      'root admin',
      RegExp(r'permanently erase', caseSensitive: false),
    ],

    // Approval-gated. The copilot pauses and asks before continuing.
    sensitiveLabels: <Pattern>[
      'delete account',
      'confirm payment',
      'publish',
      'export customer data',
      RegExp(r'cancel.*subscription', caseSensitive: false),
    ],

    // Extra "be careful" wording for product-specific risky flows.
    carefulLabels: <Pattern>[
      'invite external user',
      'make public',
    ],
  ),
)
```

You can also replace the default approval-gated list entirely with `blockedLabels`:

```dart
CopilotSafetyPolicy(
  blockedLabels: <Pattern>[
    'submit order',
    'send invoice',
    'publish release',
  ],
)
```

Use the names however your product team thinks:

| Policy field | Meaning |
|---|---|
| `deniedLabels` | Always denied |
| `doNotTouchLabels` | Alias-style list for targets the copilot must never touch |
| `blockedLabels` | Approval-gated labels; replaces the default list |
| `sensitiveLabels` | Additional approval-gated labels |
| `carefulLabels` | Additional approval-gated labels for “be careful” flows |
| `allowDestructiveActions` | Bypasses approval-gated labels, but never bypasses denied/do-not-touch labels |

### Confirmation Flow

When `accessMode` is `CopilotAccessMode.askBeforeSensitiveActions` (the default), the copilot pauses before risky actions and calls your confirmation callback:

```dart
onConfirmationRequest: (CopilotConfirmationRequest request) async {
  // request.goal    — the user's original goal
  // request.reason  — why approval is needed
  // request.action  — the planned action (if any)
  // request.node    — the target scene node (if any)

  final approved = await showDialog<bool>(
    context: context,
    builder: (_) => ConfirmDialog(
      title: 'Copilot needs approval',
      message: '${request.reason}\n\nGoal: ${request.goal}',
    ),
  );

  return approved ?? false;
}
```

If the callback is not set, sensitive actions are denied by default.

---

## Progress Events

Track the copilot's status in real time by listening to the event stream:

```dart
final controller = CopilotController.of(context);

controller.events.listen((event) {
  switch (event) {
    case CopilotStarted(:final goal):
      print('Starting: $goal');
    case CopilotSceneCaptured(:final scene):
      print('Observed ${scene.nodes.length} UI nodes');
    case CopilotLlmRequestStarted(:final step):
      print('Thinking (step $step)...');
    case CopilotLlmRequestSucceeded(:final step):
      print('Model responded (step $step)');
    case CopilotLlmRequestFailed(:final step, :final message):
      print('LLM error at step $step: $message');
    case CopilotActionPlanned(:final action):
      print('Planned: ${action.name}');
    case CopilotActionExecuted(:final action, :final result):
      print('Executed ${action.name}: ${result.success ? "ok" : result.message}');
    case CopilotConfirmationRequested(:final reason):
      print('Needs approval: $reason');
    case CopilotConfirmationResolved(:final approved):
      print(approved ? 'Approved' : 'Denied');
    case CopilotFinished(:final message):
      print('Finished: $message');
  }
});
```

### Building a Live Activity Log

```dart
class CopilotLog extends StatelessWidget {
  const CopilotLog({required this.controller, super.key});

  final CopilotController controller;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CopilotEvent>(
      stream: controller.events,
      builder: (context, snapshot) {
        final event = snapshot.data;
        if (event == null) return const SizedBox.shrink();

        return ListTile(
          leading: _iconFor(event),
          title: Text(_describe(event)),
        );
      },
    );
  }
}
```

---

## LLM Providers

### OpenAI

```dart
OpenAILlmAdapter(
  apiKey: 'YOUR_API_KEY',
  model: 'gpt-4.1',
)
```

### OpenAI-Compatible Providers

Any provider that exposes a `/chat/completions` endpoint with tool calling works:

```dart
OpenAILlmAdapter(
  apiKey: 'YOUR_PROVIDER_KEY',
  model: 'model-name',
  endpoint: Uri.parse('https://your-provider.com/v1/chat/completions'),
)
```

Examples: OpenRouter, Together AI, Groq, fireworks.ai, LocalAI, LiteLLM, and similar services.

### Custom Providers

Implement the `LlmAdapter` interface:

```dart
class MyCustomAdapter implements LlmAdapter {
  @override
  Future<LlmResponse> complete({
    required List<LlmMessage> messages,
    required List<LlmTool> tools,
  }) async {
    // Your implementation here
    return LlmResponse(
      toolCall: LlmToolCall(
        id: 'custom_1',
        name: 'tap',
        arguments: {'id': 'n1'},
      ),
    );
  }
}
```

### Testing with FakeLlmAdapter

`FakeLlmAdapter` returns predetermined tool calls in order — perfect for unit and widget tests:

```dart
final session = CopilotSession(
  goal: 'Open settings',
  config: CopilotConfig(
    llm: FakeLlmAdapter([
      const LlmToolCall(id: 'c1', name: 'tap', arguments: {'id': 'n1'}),
      const LlmToolCall(id: 'c2', name: 'done', arguments: {'summary': 'Done.'}),
    ]),
    settleDelay: Duration.zero,
  ),
  emit: (_) {},
  capture: myFakeCapture,
  executor: myFakeExecutor,
);

final result = await session.run();
expect(result, isA<CopilotCompleted>());
```

---

## Help the Copilot See Your UI

`flutter_copilot` reads Flutter's semantics tree. The copilot becomes much more reliable when important controls have clear, descriptive labels.

### Material widgets already expose good semantics

```dart
SwitchListTile(
  title: const Text('Dark mode'),
  value: darkMode,
  onChanged: setDarkMode,
)
```

### Add explicit semantics for custom controls

```dart
Semantics(
  label: 'Dark mode',
  value: darkMode ? 'On' : 'Off',
  toggled: darkMode,
  button: true,
  onTap: () => setDarkMode(!darkMode),
  child: ExcludeSemantics(
    child: MyCustomSwitch(value: darkMode),
  ),
)
```

### Label guidelines

Good labels sound like what a person would ask for:

| Good | Bad |
|---|---|
| `Save profile` | `Button 3` |
| `Email address` | `Input` |
| `Weekly summary email` | `Toggle` |
| `Open settings` | `Icon` |
| `Confirm reset` | `Yes` |
| `Cancel reset` | `No` |

Avoid icon-only controls without tooltips or semantics labels. The copilot cannot reliably choose between unlabeled buttons.

---

## Architecture

```
flutter_copilot/
├── CopilotApp              # Wraps your app, enables semantics, provides controller
├── CopilotController       # Manages runs, broadcasts events
├── CopilotSession          # The observe → plan → act loop
├── CopilotConfig           # Runtime configuration (LLM, safety, access mode)
├── CopilotRunResult        # Sealed result types
│
├── scene/
│   ├── SceneCapture        # Reads Flutter's live semantics tree
│   ├── SceneCompressor     # Reduces scene to model-friendly JSON
│   ├── SceneGraph          # Captured UI representation
│   └── SceneNode           # Individual semantics node
│
├── llm/
│   ├── LlmAdapter          # Abstract provider interface
│   ├── OpenAILlmAdapter    # OpenAI / OpenAI-compatible implementation
│   ├── FakeLlmAdapter      # Deterministic adapter for tests
│   ├── LlmMessage          # Chat message types
│   └── LlmTool             # Tool schemas exposed to the model
│
├── actions/
│   ├── CopilotAction       # Sealed action hierarchy (18 types)
│   ├── ActionExecutor      # Executes actions via semantics or pointer events
│   └── ActionResult        # Execution result with success/failure/recoverable
│
├── safety/
│   └── CopilotSafetyPolicy # Label-based guardrails for risky actions
│
└── logging/
    └── CopilotEvent        # Sealed event hierarchy (10 event types)
```

### Data flow

```
User goal
    │
    ▼
CopilotSession.run()
    │
    ├──▶ SceneCapture.capture()        → SemanticsNode tree
    ├──▶ SceneCompressor.compress()    → SceneGraph (compressed)
    ├──▶ LlmAdapter.complete()         → LlmResponse (tool calls)
    ├──▶ CopilotAction.fromToolCall()  → CopilotAction
    ├──▶ SafetyPolicy.evaluate()       → CopilotSafetyDecision
    ├──▶ ActionExecutor.execute()      → ActionResult
    │
    └──▶ Repeat until done, fail, or maxSteps
```

---

## Use Cases

### For app owners

- **Better onboarding** — Guide or perform setup tasks for new users.
- **Power user workflows** — Let advanced users skip deep navigation.
- **Support automation** — The copilot can reproduce or complete support flows.
- **Accessibility** — Reduce friction for users who struggle with complex UIs.

### For Flutter developers

- **QA automation** — Describe goals in natural language instead of writing brittle selectors.
- **Demo automation** — Record or script polished demo flows.
- **Smoke testing** — Verify critical paths after each build.
- **Internal tools** — Automate repetitive admin workflows.

### For AI builders

- **Mobile agent foundation** — A semantics-first framework for building app agents.
- **Provider-agnostic** — Swap models without changing app code.
- **Inspectable behavior** — Log, replay, and evaluate every action.
- **Custom tool extension** — Add new action types by extending `CopilotAction`.

---

## Example App

The [`example/`](example) directory contains a full Material 3 demo app showing `flutter_copilot` in action.

```bash
cd example
flutter pub get
flutter run \
  --dart-define=OPENAI_API_KEY=your_key_here \
  --dart-define=OPENAI_MODEL=gpt-4.1
```

The example app demonstrates:

- `CopilotApp` wrapping with `OpenAILlmAdapter`.
- Live event streaming with `CopilotController.events`.
- A prompt input to send goals to the copilot.
- Material 3 UI with forms, sliders, search, swipe dismiss, pull-to-refresh,
  confirmation, and proper semantics labels.

---

## Testing

### Unit tests

```bash
flutter test
```

### Example app

```bash
cd example
flutter analyze
flutter test
```

### Writing your own tests

Use `FakeLlmAdapter`, fake `SceneCapture`, and fake `ActionExecutor` to test copilot behavior without a real LLM or live UI:

```dart
testWidgets('completes a multi-step plan', (tester) async {
  final session = CopilotSession(
    goal: 'Open settings',
    config: CopilotConfig(
      llm: FakeLlmAdapter([
        const LlmToolCall(id: 'c1', name: 'tap', arguments: {'id': 'n1'}),
        const LlmToolCall(id: 'c2', name: 'done', arguments: {'summary': 'Done.'}),
      ]),
      settleDelay: Duration.zero,
    ),
    emit: (_) {},
    capture: _FakeCapture(),
    executor: _FakeExecutor(),
  );

  final result = await session.run();
  expect(result, isA<CopilotCompleted>());
});
```

---

## Contributing

Contributions are welcome through GitHub issues and pull requests.

Before opening a PR:

1. Open a GitHub issue for bugs, feature ideas, or larger changes.
2. Run `flutter analyze` and `flutter test` to ensure nothing is broken.
3. Keep PRs focused and small.
4. Match the existing Dart and Flutter style.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full guide.

---

## License

`flutter_copilot` is released under the [MIT License](LICENSE).

---

**One-liner:** `flutter_copilot` turns your Flutter app into an AI-operable interface using the semantics tree — no screenshots, no overlay chatbot, just natural-language goals becoming real UI actions.
