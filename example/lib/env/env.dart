abstract final class Env {
  static const String openaiApiKey = String.fromEnvironment('OPENAI_API_KEY');

  static const String openaiModel =
      String.fromEnvironment('OPENAI_MODEL', defaultValue: 'gpt-5.4-mini');

  static const String openaiEndpoint =
      String.fromEnvironment('OPENAI_ENDPOINT');
}
