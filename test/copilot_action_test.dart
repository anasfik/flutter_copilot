import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_copilot/flutter_copilot.dart';

void main() {
  test('parses tap tool call', () {
    final action =
        CopilotAction.fromToolCall('tap', const <String, Object?>{'id': 'n4'});
    expect(action, isA<TapAction>());
  });

  test('parses power interaction tool calls', () {
    expect(
      CopilotAction.fromToolCall(
          'long_press', const <String, Object?>{'id': 'n4'}),
      isA<LongPressAction>(),
    );
    expect(
      CopilotAction.fromToolCall(
          'keyboard_action', const <String, Object?>{'key': 'backspace'}),
      isA<KeyboardAction>(),
    );
    expect(
      CopilotAction.fromToolCall(
          'clear_text', const <String, Object?>{'id': 'n4'}),
      isA<ClearTextAction>(),
    );
    expect(
      CopilotAction.fromToolCall(
          'replace_text', const <String, Object?>{'id': 'n4', 'text': 'hello'}),
      isA<ReplaceTextAction>(),
    );
    expect(
      CopilotAction.fromToolCall('set_text_selection',
          const <String, Object?>{'id': 'n4', 'start': 0, 'end': 5}),
      isA<SetTextSelectionAction>(),
    );
    expect(
      CopilotAction.fromToolCall(
          'drag', const <String, Object?>{'id': 'n4', 'direction': 'right'}),
      isA<DragAction>(),
    );
    expect(
      CopilotAction.fromToolCall('long_press_drag',
          const <String, Object?>{'id': 'n4', 'direction': 'up'}),
      isA<LongPressDragAction>(),
    );
    expect(
      CopilotAction.fromToolCall('slider_to_value',
          const <String, Object?>{'id': 'n4', 'value': 0.75}),
      isA<SliderToValueAction>(),
    );
    expect(
      CopilotAction.fromToolCall('adjust_value',
          const <String, Object?>{'id': 'n4', 'direction': 'increase'}),
      isA<AdjustValueAction>(),
    );
    expect(
      CopilotAction.fromToolCall(
          'dismiss', const <String, Object?>{'id': 'n4'}),
      isA<DismissAction>(),
    );
    expect(
      CopilotAction.fromToolCall('system_back', const <String, Object?>{}),
      isA<SystemBackAction>(),
    );
    expect(
      CopilotAction.fromToolCall('request_confirmation',
          const <String, Object?>{'reason': 'Risky final step'}),
      isA<RequestConfirmationAction>(),
    );
  });

  test('parses done tool call', () {
    final action = CopilotAction.fromToolCall(
        'done', const <String, Object?>{'summary': 'Finished'});
    expect(action, isA<DoneAction>());
  });
}
