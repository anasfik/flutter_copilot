import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide ScrollAction;

import '../scene/scene_capture.dart';
import '../scene/scene_graph.dart';
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
      TypeTextAction(:final id, :final text) =>
        _typeText(id, text, latestScene),
      ScrollAction(:final id, :final direction, :final amount) =>
        _scroll(id, direction, amount, latestScene),
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
      node.owner?.performAction(node.id, SemanticsAction.tap);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (node.getSemanticsData().hasAction(SemanticsAction.setText)) {
        node.owner?.performAction(node.id, SemanticsAction.setText, text);
      } else {
        await SystemChannels.textInput.invokeMethod<void>(
          'TextInput.setEditingState',
          TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          ).toJSON(),
        );
      }
      return ActionResult.success('Typed text into $id.');
    } on Object catch (error) {
      return ActionResult.failure('Text input failed for $id: $error');
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

  Offset _globalCenter(SemanticsNode node) {
    final data = node.getSemanticsData();
    final transform = data.transform ?? Matrix4.identity();
    return MatrixUtils.transformPoint(transform, data.rect.center);
  }
}
