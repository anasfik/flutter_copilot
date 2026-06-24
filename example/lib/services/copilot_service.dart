import 'package:flutter_copilot/flutter_copilot.dart';

import '../env/env.dart';
import 'demo_confirmation.dart';
import 'demo_llm_adapter.dart';

CopilotConfig buildCopilotConfig() {
  const demoMode =
      bool.fromEnvironment('COPILOT_DEMO_MODE', defaultValue: true);
  final apiKey = Env.openaiApiKey.trim();
  final endpoint = Env.openaiEndpoint.trim();
  final useMock = demoMode || apiKey.isEmpty || apiKey == 'demo';

  return CopilotConfig(
    llm: useMock
        ? DemoLlmAdapter()
        : OpenAILlmAdapter(
            apiKey: apiKey,
            model: Env.openaiModel,
            endpoint: endpoint.isEmpty ? null : Uri.parse(endpoint),
          ),
    accessMode: CopilotAccessMode.askBeforeSensitiveActions,
    onConfirmationRequest: confirmCopilotAction,
    settleDelay: const Duration(milliseconds: 250),
    debugLogging: true,
  );
}
