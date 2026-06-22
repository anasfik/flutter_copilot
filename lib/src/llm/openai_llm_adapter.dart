import 'dart:convert';

import 'package:http/http.dart' as http;

import 'llm_adapter.dart';
import 'llm_message.dart';
import 'llm_tool.dart';

/// LLM adapter for OpenAI and OpenAI-compatible Chat Completions endpoints.
class OpenAILlmAdapter implements LlmAdapter {
  /// Creates an OpenAI-compatible adapter.
  OpenAILlmAdapter({
    required this.apiKey,
    this.model = 'gpt-4.1',
    Uri? endpoint,
    http.Client? client,
  })  : endpoint =
            endpoint ?? Uri.parse('https://api.openai.com/v1/chat/completions'),
        _client = client ?? http.Client();

  /// API key sent as a bearer token.
  final String apiKey;

  /// Model name passed to the provider.
  final String model;

  /// Chat Completions endpoint.
  final Uri endpoint;
  final http.Client _client;

  /// Sends [messages] and [tools] to the configured endpoint.
  @override
  Future<LlmResponse> complete({
    required List<LlmMessage> messages,
    required List<LlmTool> tools,
  }) async {
    final response = await _client.post(
      endpoint,
      headers: <String, String>{
        'authorization': 'Bearer $apiKey',
        'content-type': 'application/json',
      },
      body: jsonEncode(<String, Object?>{
        'model': model,
        'messages': messages.map(_messageToJson).toList(),
        'tools': tools.map((tool) => tool.toOpenAIToolJson()).toList(),
        'tool_choice': 'auto',
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw LlmException(
          'OpenAI request failed (${response.statusCode}): ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, Object?>;
    final choices = decoded['choices'] as List<Object?>? ?? const <Object?>[];
    if (choices.isEmpty) {
      throw const LlmException('OpenAI response did not contain choices.');
    }

    final choice = choices.first as Map<String, Object?>;
    final message = choice['message'] as Map<String, Object?>;
    final toolCalls = message['tool_calls'] as List<Object?>?;
    if (toolCalls != null && toolCalls.isNotEmpty) {
      final calls = <LlmToolCall>[
        for (final toolCall in toolCalls)
          if (toolCall is Map<Object?, Object?>)
            _toolCallFromJson(toolCall.cast<String, Object?>()),
      ];
      if (calls.isEmpty) {
        return LlmResponse(content: message['content'] as String? ?? '');
      }
      return LlmResponse(
        content: message['content'] as String? ?? '',
        toolCall: calls.first,
        toolCalls: calls,
      );
    }

    return LlmResponse(content: message['content'] as String? ?? '');
  }

  Map<String, Object?> _messageToJson(LlmMessage message) {
    return <String, Object?>{
      'role': message.role.name,
      'content': message.content,
      if (message.toolCallId != null) 'tool_call_id': message.toolCallId,
    };
  }

  LlmToolCall _toolCallFromJson(Map<String, Object?> toolCall) {
    final function =
        (toolCall['function'] as Map<Object?, Object?>).cast<String, Object?>();
    final rawArgs = function['arguments'] as String? ?? '{}';
    return LlmToolCall(
      id: toolCall['id'] as String? ??
          'tool_${DateTime.now().microsecondsSinceEpoch}',
      name: function['name'] as String? ?? '',
      arguments: jsonDecode(rawArgs) as Map<String, Object?>,
    );
  }
}

/// Exception thrown when an LLM request or response fails.
class LlmException implements Exception {
  /// Creates an LLM exception.
  const LlmException(this.message);

  /// Human-readable failure message.
  final String message;

  @override
  String toString() => 'LlmException: $message';
}
