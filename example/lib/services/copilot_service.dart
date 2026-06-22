import 'package:flutter_copilot/flutter_copilot.dart';

import '../env/env.dart';

CopilotConfig buildCopilotConfig() {
  final endpoint = Env.openaiEndpoint.trim();

  return CopilotConfig(
    llm: OpenAILlmAdapter(
      apiKey: Env.openaiApiKey,
      model: Env.openaiModel,
      endpoint: endpoint.isEmpty ? null : Uri.parse(endpoint),
    ),
    settleDelay: const Duration(milliseconds: 250),
    debugLogging: true,
  );
}
