import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide DismissAction, ScrollAction;

import '../scene/scene_capture.dart';
import '../scene/scene_graph.dart';
import '../scene/scene_node.dart';
import 'action_result.dart';
import 'copilot_action.dart';

/// Executes model-selected UI actions against Flutter semantics.
class ActionExecutor {
  /// Creates an action executor.
  ActionExecutor({
    SceneCapture? capture,
    this.pointerDelay = const Duration(milliseconds: 50),
  }) : _capture = capture ?? SceneCapture();

  final SceneCapture _capture;

  /// Delay between pointer down/up events.
  final Duration pointerDelay;

  /// Executes [action] using [latestScene] for node lookup.
  Future<ActionResult> execute(
      CopilotAction action, SceneGraph latestScene) async {
    return switch (action) {
      TapAction(:final id) => _tap(id, latestScene),
      LongPressAction(:final id) => _longPress(id, latestScene),
      TypeTextAction(:final id, :final text) =>
        _typeText(id, text, latestScene),
      ClearTextAction(:final id) => _clearText(id, latestScene),
      ReplaceTextAction(:final id, :final text) =>
        _replaceText(id, text, latestScene),
      SetTextSelectionAction(:final id, :final start, :final end) =>
        _setTextSelection(id, start, end, latestScene),
      KeyboardAction(:final key) => _keyboardAction(key),
      ScrollAction(:final id, :final direction, :final amount) =>
        _scroll(id, direction, amount, latestScene),
      DragAction(:final id, :final direction, :final amount) =>
        _drag(id, direction, amount, latestScene),
      LongPressDragAction(:final id, :final direction, :final amount) =>
        _longPressDrag(id, direction, amount, latestScene),
      SliderToValueAction(:final id, :final value) =>
        _sliderToValue(id, value, latestScene),
      AdjustValueAction(:final id, :final direction, :final steps) =>
        _adjustValue(id, direction, steps, latestScene),
      DismissAction(:final id) => _dismiss(id, latestScene),
      SystemBackAction() => _systemBack(latestScene),
      RequestConfirmationAction() => Future<ActionResult>.value(
          ActionResult.failure('Confirmation must be handled by the session.')),
      WaitAction(:final duration) => _wait(duration),
      DoneAction() =>
        Future<ActionResult>.value(ActionResult.success('Goal completed.')),
      FailAction(:final reason) => Future<ActionResult>.value(
          ActionResult.failure(reason, recoverable: false)),
      UnknownAction(:final name) => Future<ActionResult>.value(
          ActionResult.failure('Unknown action: $name', recoverable: true),
        ),
    };
  }

  Future<ActionResult> _longPress(String id, SceneGraph graph) async {
    final node = _capture.resolve(graph, id);
    if (node == null) {
      return ActionResult.failure(
          'Node $id was not found. The screen may have changed.');
    }

    try {
      if (node.getSemanticsData().hasAction(SemanticsAction.longPress)) {
        node.owner?.performAction(node.id, SemanticsAction.longPress);
        return ActionResult.success('Long-pressed $id with semantics action.');
      }
      await _pointerLongPress(node);
      return ActionResult.success('Long-pressed $id with pointer events.');
    } on Object catch (error) {
      return ActionResult.failure('Long press failed for $id: $error');
    }
  }

  Future<ActionResult> _tap(String id, SceneGraph graph) async {
    final node = _capture.resolve(graph, id);
    if (node == null) {
      return ActionResult.failure(
          'Node $id was not found. The screen may have changed.');
    }

    try {
      if (node.getSemanticsData().hasAction(SemanticsAction.tap)) {
        node.owner?.performAction(node.id, SemanticsAction.tap);
        return ActionResult.success('Tapped $id with semantics action.');
      }
      await _pointerTap(node);
      return ActionResult.success('Tapped $id with pointer events.');
    } on Object catch (error) {
      return ActionResult.failure('Tap failed for $id: $error');
    }
  }

  Future<ActionResult> _typeText(
      String id, String text, SceneGraph graph) async {
    final node = _capture.resolve(graph, id);
    if (node == null) {
      return ActionResult.failure(
          'Node $id was not found. The screen may have changed.');
    }

    try {
      await _setText(node, text);
      return ActionResult.success('Typed text into $id.');
    } on Object catch (error) {
      return ActionResult.failure('Text input failed for $id: $error');
    }
  }

  Future<ActionResult> _clearText(String id, SceneGraph graph) async {
    final node = _capture.resolve(graph, id);
    if (node == null) {
      return ActionResult.failure(
          'Node $id was not found. The screen may have changed.');
    }

    try {
      await _setText(node, '');
      return ActionResult.success('Cleared text in $id.');
    } on Object catch (error) {
      return ActionResult.failure('Clear text failed for $id: $error');
    }
  }

  Future<ActionResult> _replaceText(
      String id, String text, SceneGraph graph) async {
    final node = _capture.resolve(graph, id);
    if (node == null) {
      return ActionResult.failure(
          'Node $id was not found. The screen may have changed.');
    }

    try {
      await _setText(node, text);
      return ActionResult.success('Replaced text in $id.');
    } on Object catch (error) {
      return ActionResult.failure('Replace text failed for $id: $error');
    }
  }

  Future<ActionResult> _setTextSelection(
      String id, int start, int end, SceneGraph graph) async {
    final node = _capture.resolve(graph, id);
    if (node == null) {
      return ActionResult.failure(
          'Node $id was not found. The screen may have changed.');
    }

    try {
      node.owner?.performAction(node.id, SemanticsAction.tap);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final text = node.getSemanticsData().value;
      final length = text.length;
      final selectionStart = start.clamp(0, length).toInt();
      final selectionEnd = end.clamp(0, length).toInt();
      await _setEditingState(
        TextEditingValue(
          text: text,
          selection: TextSelection(
            baseOffset: selectionStart,
            extentOffset: selectionEnd,
          ),
        ),
      );
      return ActionResult.success('Set text selection in $id.');
    } on Object catch (error) {
      return ActionResult.failure('Set text selection failed for $id: $error');
    }
  }

  Future<ActionResult> _keyboardAction(String key) async {
    try {
      if (key == 'backspace') {
        await _sendKey(
            LogicalKeyboardKey.backspace, PhysicalKeyboardKey.backspace);
      } else if (key == 'delete') {
        await _sendKey(LogicalKeyboardKey.delete, PhysicalKeyboardKey.delete);
      } else if (key == 'enter') {
        await _sendKey(LogicalKeyboardKey.enter, PhysicalKeyboardKey.enter);
      } else if (key == 'done' ||
          key == 'submit' ||
          key == 'search' ||
          key == 'go') {
        await _sendKey(LogicalKeyboardKey.enter, PhysicalKeyboardKey.enter);
      } else if (key == 'next') {
        await _sendKey(LogicalKeyboardKey.tab, PhysicalKeyboardKey.tab);
      } else if (key == 'previous' || key == 'shift_tab') {
        await _sendKey(
            LogicalKeyboardKey.shiftLeft, PhysicalKeyboardKey.shiftLeft);
        await _sendKey(LogicalKeyboardKey.tab, PhysicalKeyboardKey.tab);
        await _sendKey(
            LogicalKeyboardKey.shiftLeft, PhysicalKeyboardKey.shiftLeft,
            down: false);
      } else if (key == 'escape') {
        await _sendKey(LogicalKeyboardKey.escape, PhysicalKeyboardKey.escape);
      } else if (key == 'tab') {
        await _sendKey(LogicalKeyboardKey.tab, PhysicalKeyboardKey.tab);
      } else if (key == 'select_all') {
        await _sendKey(
            LogicalKeyboardKey.controlLeft, PhysicalKeyboardKey.controlLeft);
        await _sendKey(LogicalKeyboardKey.keyA, PhysicalKeyboardKey.keyA,
            character: 'a');
        await _sendKey(
            LogicalKeyboardKey.controlLeft, PhysicalKeyboardKey.controlLeft,
            down: false);
      } else {
        return ActionResult.failure('Unsupported keyboard action: $key',
            recoverable: true);
      }
      return ActionResult.success('Sent keyboard action $key.');
    } on Object catch (error) {
      return ActionResult.failure('Keyboard action failed for $key: $error');
    }
  }

  Future<ActionResult> _scroll(
      String id, String direction, String amount, SceneGraph graph) async {
    final node = _capture.resolve(graph, id);
    if (node == null) {
      return ActionResult.failure(
          'Node $id was not found. The screen may have changed.');
    }

    final action = switch (direction) {
      'up' => SemanticsAction.scrollUp,
      'down' => SemanticsAction.scrollDown,
      'left' => SemanticsAction.scrollLeft,
      'right' => SemanticsAction.scrollRight,
      _ => SemanticsAction.scrollDown,
    };

    try {
      if (node.getSemanticsData().hasAction(action)) {
        node.owner?.performAction(node.id, action);
        return ActionResult.success('Scrolled $id $direction.');
      }
      await _pointerScroll(node, direction, amount);
      return ActionResult.success(
          'Scrolled $id $direction with pointer events.');
    } on Object catch (error) {
      return ActionResult.failure('Scroll failed for $id: $error');
    }
  }

  Future<ActionResult> _drag(
      String id, String direction, String amount, SceneGraph graph) async {
    final node = _capture.resolve(graph, id);
    if (node == null) {
      return ActionResult.failure(
          'Node $id was not found. The screen may have changed.');
    }

    try {
      await _pointerDrag(node, direction, amount);
      return ActionResult.success('Dragged $id $direction.');
    } on Object catch (error) {
      return ActionResult.failure('Drag failed for $id: $error');
    }
  }

  Future<ActionResult> _longPressDrag(
      String id, String direction, String amount, SceneGraph graph) async {
    final node = _capture.resolve(graph, id);
    if (node == null) {
      return ActionResult.failure(
          'Node $id was not found. The screen may have changed.');
    }

    try {
      await _pointerDrag(node, direction, amount, holdFirst: true);
      return ActionResult.success('Long-press-dragged $id $direction.');
    } on Object catch (error) {
      return ActionResult.failure('Long press drag failed for $id: $error');
    }
  }

  Future<ActionResult> _sliderToValue(
      String id, double value, SceneGraph graph) async {
    final node = _capture.resolve(graph, id);
    if (node == null) {
      return ActionResult.failure(
          'Node $id was not found. The screen may have changed.');
    }

    try {
      await _pointerSliderToValue(node, value);
      return ActionResult.success('Dragged $id to $value.');
    } on Object catch (error) {
      return ActionResult.failure('Slider drag failed for $id: $error');
    }
  }

  Future<ActionResult> _adjustValue(
      String id, String direction, int steps, SceneGraph graph) async {
    final node = _capture.resolve(graph, id);
    if (node == null) {
      return ActionResult.failure(
          'Node $id was not found. The screen may have changed.');
    }

    final action = switch (direction) {
      'increase' => SemanticsAction.increase,
      'decrease' => SemanticsAction.decrease,
      _ => null,
    };
    if (action == null) {
      return ActionResult.failure(
          'Unsupported adjust_value direction: $direction');
    }

    try {
      if (!node.getSemanticsData().hasAction(action)) {
        return ActionResult.failure(
            'Node $id does not support semantic $direction.');
      }
      final count = steps.clamp(1, 20).toInt();
      for (var i = 0; i < count; i++) {
        node.owner?.performAction(node.id, action);
        await Future<void>.delayed(pointerDelay);
      }
      return ActionResult.success('Adjusted $id $direction $steps step(s).');
    } on Object catch (error) {
      return ActionResult.failure('Adjust value failed for $id: $error');
    }
  }

  Future<ActionResult> _dismiss(String id, SceneGraph graph) async {
    final node = _capture.resolve(graph, id);
    if (node == null) {
      return ActionResult.failure(
          'Node $id was not found. The screen may have changed.');
    }

    try {
      if (node.getSemanticsData().hasAction(SemanticsAction.dismiss)) {
        node.owner?.performAction(node.id, SemanticsAction.dismiss);
        return ActionResult.success('Dismissed $id.');
      }
      await _pointerDrag(node, 'left', 'large');
      return ActionResult.success('Dismissed $id with drag fallback.');
    } on Object catch (error) {
      return ActionResult.failure('Dismiss failed for $id: $error');
    }
  }

  Future<ActionResult> _systemBack(SceneGraph graph) async {
    if (_textFieldHasFocus(graph)) {
      return ActionResult.failure(
        'Text input is focused. Use keyboard_action escape or enter first.',
      );
    }

    try {
      final context = WidgetsBinding.instance.rootElement;
      if (context == null) {
        return ActionResult.failure('No root widget is mounted.');
      }
      final popped = await Navigator.maybePop(context);
      if (!popped) {
        return ActionResult.failure('No route could be popped.');
      }
      return ActionResult.success('System back was handled.');
    } on Object catch (error) {
      return ActionResult.failure('System back failed: $error');
    }
  }

  Future<ActionResult> _wait(Duration duration) async {
    await Future<void>.delayed(duration);
    return ActionResult.success('Waited ${duration.inMilliseconds}ms.');
  }

  Future<void> _pointerTap(SemanticsNode node) async {
    final position = _globalCenter(node);
    GestureBinding.instance
        .handlePointerEvent(PointerDownEvent(position: position));
    await Future<void>.delayed(pointerDelay);
    GestureBinding.instance
        .handlePointerEvent(PointerUpEvent(position: position));
  }

  Future<void> _setText(SemanticsNode node, String text) async {
    node.owner?.performAction(node.id, SemanticsAction.tap);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (node.getSemanticsData().hasAction(SemanticsAction.setText)) {
      node.owner?.performAction(node.id, SemanticsAction.setText, text);
      return;
    }
    await _setEditingState(
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );
  }

  Future<void> _setEditingState(TextEditingValue value) {
    return SystemChannels.textInput.invokeMethod<void>(
      'TextInput.setEditingState',
      value.toJSON(),
    );
  }

  Future<void> _pointerLongPress(SemanticsNode node) async {
    final position = _globalCenter(node);
    GestureBinding.instance
        .handlePointerEvent(PointerDownEvent(position: position));
    await Future<void>.delayed(const Duration(milliseconds: 550));
    GestureBinding.instance
        .handlePointerEvent(PointerUpEvent(position: position));
  }

  Future<void> _pointerScroll(
      SemanticsNode node, String direction, String amount) async {
    final start = _globalCenter(node);
    final distance = switch (amount) {
      'small' => 120.0,
      'large' => 480.0,
      _ => 260.0,
    };
    final delta = switch (direction) {
      'up' => Offset(0, distance),
      'down' => Offset(0, -distance),
      'left' => Offset(distance, 0),
      'right' => Offset(-distance, 0),
      _ => Offset(0, -distance),
    };
    const pointer = 24;
    GestureBinding.instance.handlePointerEvent(
        PointerDownEvent(pointer: pointer, position: start));
    GestureBinding.instance.handlePointerEvent(
        PointerMoveEvent(pointer: pointer, position: start + delta));
    await Future<void>.delayed(pointerDelay);
    GestureBinding.instance.handlePointerEvent(
        PointerUpEvent(pointer: pointer, position: start + delta));
  }

  Future<void> _pointerDrag(
    SemanticsNode node,
    String direction,
    String amount, {
    bool holdFirst = false,
  }) async {
    final distance = switch (amount) {
      'small' => 80.0,
      'large' => 420.0,
      _ => 220.0,
    };
    final delta = _directionOffset(direction, distance);
    await _dragFromTo(_globalCenter(node), _globalCenter(node) + delta,
        holdFirst: holdFirst);
  }

  Future<void> _pointerSliderToValue(SemanticsNode node, double value) async {
    final data = node.getSemanticsData();
    final transform = data.transform ?? Matrix4.identity();
    final y = data.rect.center.dy;
    final target = MatrixUtils.transformPoint(
      transform,
      Offset(
        data.rect.left + (data.rect.width * value.clamp(0.0, 1.0).toDouble()),
        y,
      ),
    );
    await _dragFromTo(_globalCenter(node), target);
  }

  Future<void> _dragFromTo(Offset start, Offset end,
      {bool holdFirst = false}) async {
    const pointer = 25;
    GestureBinding.instance.handlePointerEvent(
        PointerDownEvent(pointer: pointer, position: start));
    if (holdFirst) {
      await Future<void>.delayed(const Duration(milliseconds: 550));
    }
    for (var i = 1; i <= 5; i++) {
      final t = i / 5;
      GestureBinding.instance.handlePointerEvent(PointerMoveEvent(
        pointer: pointer,
        position: Offset.lerp(start, end, t)!,
      ));
      await Future<void>.delayed(
          Duration(milliseconds: pointerDelay.inMilliseconds ~/ 2));
    }
    GestureBinding.instance
        .handlePointerEvent(PointerUpEvent(pointer: pointer, position: end));
  }

  Offset _directionOffset(String direction, double distance) {
    return switch (direction) {
      'up' => Offset(0, -distance),
      'down' => Offset(0, distance),
      'left' => Offset(-distance, 0),
      'right' => Offset(distance, 0),
      _ => Offset.zero,
    };
  }

  Future<void> _sendKey(
      LogicalKeyboardKey logical, PhysicalKeyboardKey physical,
      {String? character, bool down = true}) async {
    final event = down
        ? KeyDownEvent(
            logicalKey: logical,
            physicalKey: physical,
            timeStamp: Duration.zero,
            character: character,
          )
        : KeyUpEvent(
            logicalKey: logical,
            physicalKey: physical,
            timeStamp: Duration.zero,
          );
    HardwareKeyboard.instance.handleKeyEvent(event);
    await Future<void>.delayed(pointerDelay);
    if (down &&
        logical != LogicalKeyboardKey.controlLeft &&
        logical != LogicalKeyboardKey.shiftLeft) {
      await _sendKey(logical, physical, down: false);
    }
  }

  bool _textFieldHasFocus(SceneGraph graph) {
    return graph.nodes.any((node) =>
        node.flags.contains(SceneFlag.textField) &&
        node.flags.contains(SceneFlag.focused));
  }

  Offset _globalCenter(SemanticsNode node) {
    final data = node.getSemanticsData();
    final transform = data.transform ?? Matrix4.identity();
    return MatrixUtils.transformPoint(transform, data.rect.center);
  }
}
