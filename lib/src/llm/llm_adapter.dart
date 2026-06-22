import 'llm_message.dart';
import 'llm_tool.dart';

/// Interface implemented by model providers.
abstract interface class LlmAdapter {
  /// Returns the model response for [messages] and available [tools].
  Future<LlmResponse> complete({
    required List<LlmMessage> messages,
    required List<LlmTool> tools,
  });
}

/// Response returned by an [LlmAdapter].
class LlmResponse {
  /// Creates an LLM response.
  const LlmResponse({
    this.content = '',
    this.toolCall,
    this.toolCalls = const <LlmToolCall>[],
  });

  /// Plain text response content, if any.
  final String content;

  /// Single tool call for adapters that return one call.
  final LlmToolCall? toolCall;

  /// Tool calls returned by adapters that support batching.
  final List<LlmToolCall> toolCalls;

  /// All tool calls normalized into a list.
  List<LlmToolCall> get allToolCalls {
    if (toolCalls.isNotEmpty) {
      return toolCalls;
    }
    final call = toolCall;
    return call == null ? const <LlmToolCall>[] : <LlmToolCall>[call];
  }
}

/// A model-selected tool invocation.
class LlmToolCall {
  /// Creates a tool call.
  const LlmToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });

  /// Provider-specific call id.
  final String id;

  /// Tool/function name.
  final String name;

  /// Tool/function arguments.
  final Map<String, Object?> arguments;
}
