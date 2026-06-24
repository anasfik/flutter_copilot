# flutter_copilot example

Interactive demo app for `flutter_copilot`.

By default the example runs in mock mode, so you can try the UI without an API
key:

```bash
fvm flutter run -d linux
```

Try prompts such as:

- Open settings and enable dark mode
- Go to profile, set the display name and email, then save
- Open tasks and mark Write release notes as done
- Open settings and set the font scale slider high
- Reset demo data after asking me for confirmation

The mock LLM reads the same semantics JSON a real model receives, picks visible
node ids, and drives the app through normal copilot tool calls. It is meant for
repeatable demos.

To use a real OpenAI-compatible provider, disable mock mode:

```bash
fvm flutter run -d linux \
  --dart-define=COPILOT_DEMO_MODE=false \
  --dart-define=OPENAI_API_KEY=your_key_here \
  --dart-define=OPENAI_MODEL=gpt-5.4-mini
```

For a compatible provider with a custom endpoint:

```bash
fvm flutter run -d linux \
  --dart-define=COPILOT_DEMO_MODE=false \
  --dart-define=OPENAI_API_KEY=your_provider_key_here \
  --dart-define=OPENAI_MODEL=openrouter/auto \
  --dart-define=OPENAI_ENDPOINT=https://openrouter.ai/api/v1/chat/completions
```
