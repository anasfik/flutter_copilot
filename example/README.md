# flutter_copilot example

Interactive demo app for `flutter_copilot` using the real
`OpenAILlmAdapter`.

Run it with an OpenAI API key:

```bash
fvm flutter run -d linux \
  --dart-define=OPENAI_API_KEY=your_key_here \
  --dart-define=OPENAI_MODEL=gpt-4.1
```

For an OpenAI-compatible provider:

```bash
fvm flutter run -d linux \
  --dart-define=OPENAI_API_KEY=your_provider_key_here \
  --dart-define=OPENAI_MODEL=openrouter/auto \
  --dart-define=OPENAI_ENDPOINT=https://openrouter.ai/api/v1/chat/completions
```

Try prompts such as:

- Open settings and enable dark mode
- Go to profile, set the display name and email, then save
- Open tasks and mark Write release notes as done
- Go to tasks and show only active tasks
- Open settings and enable notifications and weekly email
- Open settings and set the font scale slider high
- Add the starter kit to the cart
- Open tasks and swipe Archive old invoices away
- Open tasks, search for release, then clear the search
- Reset demo data after asking me for confirmation

The app includes tabs, forms, switches, segmented controls, a slider,
cart buttons, search, pull-to-refresh, dismiss/confirmation flows, and a live
copilot event log so you can watch the agent plan and act through Flutter
semantics.
