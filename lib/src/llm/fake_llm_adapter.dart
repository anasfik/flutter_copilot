import 'llm_adapter.dart';
import 'llm_message.dart';
import 'llm_tool.dart';

/// Deterministic adapter for tests and demos.
class FakeLlmAdapter implements LlmAdapter {
  /// Creates a fake adapter that returns [calls] in order.
  FakeLlmAdapter(this.calls);

  /// Tool calls returned one at a time.
  final List<LlmToolCall> calls;
  int _index = 0;

  /// Returns the next fake response.
  @override
  Future<LlmResponse> complete({
    required List<LlmMessage> messages,
    required List<LlmTool> tools,
  }) async {
    if (_index >= calls.length) {
      return const LlmResponse(
        toolCall: LlmToolCall(
          id: 'fake_done',
          name: 'done',
          arguments: <String, Object?>{'summary': 'Fake plan completed.'},
        ),
      );
    }
    final call = calls[_index++];
    return LlmResponse(toolCall: call);
  }
}
