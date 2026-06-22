# flutter_copilot

Give your Flutter app an invisible AI copilot that can understand the current UI, choose actions, tap, type, scroll, wait, and keep going until a user goal is complete.

`flutter_copilot` works from Flutter's semantics tree. It does not need screenshots or an overlay chat UI. You wrap your app with `CopilotApp`, provide an OpenAI-compatible LLM, then call `CopilotController.run(...)` with a natural-language goal.

## Demo


https://github.com/user-attachments/assets/7dcb8504-00b3-4f68-80d3-19f74df75417


## Idea & Motivation

Imagine an app full of options, screens, forms, buttons, tabs, dialogs, and settings. Instead of making the user find every control manually, `flutter_copilot` can carry out tasks inside your app from natural language:

```text
Go to settings, turn on dark mode, enable weekly summary emails, and save.
```

It observes the current Flutter UI, decides the next visible action, taps, types, scrolls, waits, and repeats until the task is done.

See the [example app](example) to see how it works in practice, and check out [Help the Copilot See Your UI](#help-the-copilot-see-your-ui) to help the copilot understand your most complex flows.

### What It Can Do

It can:

1. Navigate between screens and tabs.
2. Tap buttons, switches, checkboxes, list items, and navigation controls.
3. Type into visible text fields.
4. Scroll visible scrollable areas.
5. Wait for loading or animations.
6. Execute several independent visible actions in one model step.
7. Report progress through events so you can show a live activity log.
8. Stop safely on blocked, destructive, or impossible actions.
9. Much more as LLMs and your UI improve!

## Install & Usage

```yaml
dependencies:
  flutter_copilot: ^0.9.1
```

### Supported Providers

Currently supported:

1. OpenAI.
2. OpenAI API-compatible providers, including OpenRouter and similar `/chat/completions` endpoints that support tool calling.

### Setup

Wrap your app with `CopilotApp` and configure the LLM:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_copilot/flutter_copilot.dart';

void main() {
  runApp(
    CopilotApp(
      config: CopilotConfig(
        // compatible with all OpenAI and OpenAI API-compatible providers
        llm: OpenAILlmAdapter(
          apiKey: 'YOUR_KEY_HERE',
          model: 'THE_MODEL_YOU_WANT_TO_USE',
          // optional: if using a compatible provider with a different endpoint
          endpoint: Uri.parse('https://api.openai.com/v1/chat/completions'),
        ),
        debugLogging: true,
      ),
      child: const YourApp(),
    ),
  );
}
```

### Quick Usage

Anywhere below the `CopilotApp` you configured, get the controller and run your first prompt:

```dart
final controller = CopilotController.of(context);
final result = await controller.run(
  'Open settings and turn on dark mode, then go back and open profile and update the display name to Anas, then save.',
);
```

### Help the Copilot See Your UI

`flutter_copilot` reads semantics, so your app becomes much easier to automate when important controls have clear labels.

Most Material widgets already expose good semantics:

```dart
SwitchListTile(
  title: const Text('Dark mode'),
  value: darkMode,
  onChanged: setDarkMode,
)
```

For custom controls, add explicit semantics:

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

Good labels sound like what a person would ask for:

- `Save profile`
- `Email address`
- `Weekly summary email`
- `Open settings`
- `Confirm reset`
- `Cancel reset`

Avoid icon-only controls without tooltips or semantics labels. The copilot cannot reliably choose between unlabeled buttons.

### Show Progress in Your App

You can track the copilot status or progress anytime, anywhere below `CopilotApp`, by listening to `CopilotController.events`.

```dart
CopilotController.of(context).events.listen((event) {
  print('Copilot event: $event');
});
```

## Safety

`flutter_copilot` ships with `CopilotSafetyPolicy.defaults`, which blocks planned actions when the target control label, value, or hint matches risky text like logout, payment, transfer, purchase, or account deletion.

```dart
CopilotSafetyPolicy(
  blockedLabels: const <Pattern>[
    'delete account',
    'confirm payment',
    'send money',
  ],
)
```

When a planned action matches `blockedLabels`, the run stops instead of executing it.

## Contributing

Contributions are welcome through GitHub issues and pull requests. See [CONTRIBUTING.md](CONTRIBUTING.md) for the short guide.

## License

`flutter_copilot` is released under the MIT License. See [LICENSE](LICENSE).
