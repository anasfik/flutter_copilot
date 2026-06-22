# flutter_copilot example

Basic demo app for `flutter_copilot`.

Run it with:

```bash
flutter run -d linux \
  --dart-define=OPENAI_API_KEY=your_key_here \
  --dart-define=OPENAI_MODEL=gpt-5.4-mini
```

For an OpenAI-compatible provider:

```bash
flutter run -d linux \
  --dart-define=OPENAI_API_KEY=your_provider_key_here \
  --dart-define=OPENAI_MODEL=openrouter/auto \
  --dart-define=OPENAI_ENDPOINT=https://openrouter.ai/api/v1/chat/completions
```
