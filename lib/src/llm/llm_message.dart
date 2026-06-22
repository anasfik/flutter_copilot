/// Chat message role.
enum LlmRole { system, user, assistant, tool }

/// Chat message sent to an LLM adapter.
class LlmMessage {
  /// Creates a chat message.
  const LlmMessage({
    required this.role,
    required this.content,
    this.toolCallId,
  });

  /// Message role.
  final LlmRole role;

  /// Message content.
  final String content;

  /// Tool call id for tool-role messages.
  final String? toolCallId;

  /// Creates a system message.
  factory LlmMessage.system(String content) =>
      LlmMessage(role: LlmRole.system, content: content);

  /// Creates a user message.
  factory LlmMessage.user(String content) =>
      LlmMessage(role: LlmRole.user, content: content);

  /// Creates an assistant message.
  factory LlmMessage.assistant(String content) =>
      LlmMessage(role: LlmRole.assistant, content: content);

  /// Creates a tool result message.
  factory LlmMessage.tool(String id, String content) {
    return LlmMessage(role: LlmRole.tool, content: content, toolCallId: id);
  }
}
