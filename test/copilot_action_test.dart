import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_copilot/flutter_copilot.dart';

void main() {
  test('parses tap tool call', () {
    final action =
        CopilotAction.fromToolCall('tap', const <String, Object?>{'id': 'n4'});
    expect(action, isA<TapAction>());
  });

  test('parses done tool call', () {
    final action = CopilotAction.fromToolCall(
        'done', const <String, Object?>{'summary': 'Finished'});
    expect(action, isA<DoneAction>());
  });
}
