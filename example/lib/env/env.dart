abstract final class Env {
  static const String openaiApiKey = String.fromEnvironment('OPENAI_API_KEY');

  static const String openaiModel =
      String.fromEnvironment('OPENAI_MODEL', defaultValue: 'gpt-4.1');

  static const String openaiEndpoint =
      String.fromEnvironment('OPENAI_ENDPOINT');
}
