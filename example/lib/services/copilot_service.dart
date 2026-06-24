import 'package:flutter_copilot/flutter_copilot.dart';

import '../env/env.dart';
import 'demo_confirmation.dart';

CopilotConfig buildCopilotConfig() {
  final apiKey = Env.openaiApiKey.trim();
  final endpoint = Env.openaiEndpoint.trim();

  return CopilotConfig(
    llm: OpenAILlmAdapter(
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
