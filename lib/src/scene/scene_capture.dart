import 'package:flutter/rendering.dart';

import 'scene_graph.dart';
import 'scene_node.dart';

/// Captures the current Flutter semantics tree.
class SceneCapture {
  /// Creates a scene capture helper.
  SceneCapture({this.includeGeometry = false});

  /// Whether geometry should be included by callers that serialize scenes.
  final bool includeGeometry;

  /// Captures the current semantics tree as a [SceneGraph].
  SceneGraph capture() {
    final root = _rootSemanticsNode();
    if (root == null) {
      return SceneGraph(
          nodes: const <SceneNode>[], idToSemanticsId: const <String, int>{});
    }

    final nodes = <SceneNode>[];
    var nextId = 1;

    void visit(SemanticsNode node, int depth) {
      final publicId = 'n${nextId++}';
      nodes.add(_toSceneNode(node, publicId, depth));
      node.visitChildren((child) {
        visit(child, depth + 1);
        return true;
      });
    }

    visit(root, 0);

    return SceneGraph(
      nodes: nodes,
      idToSemanticsId: <String, int>{
        for (final node in nodes) node.id: node.semanticsId,
      },
    );
  }

  /// Resolves a public scene node id back to a live semantics node.
  SemanticsNode? resolve(SceneGraph graph, String publicId) {
    final semanticsId = graph.semanticsIdFor(publicId);
    if (semanticsId == null) {
      return null;
    }
    final root = _rootSemanticsNode();
    if (root == null) {
      return null;
    }
    return _find(root, semanticsId);
  }

  SemanticsNode? _find(SemanticsNode node, int id) {
    if (node.id == id) {
      return node;
    }
    SemanticsNode? match;
    node.visitChildren((child) {
      match = _find(child, id);
      return match == null;
    });
    return match;
  }

  SceneNode _toSceneNode(SemanticsNode node, String publicId, int depth) {
    final data = node.getSemanticsData();
    return SceneNode(
      id: publicId,
      semanticsId: node.id,
      rect: data.rect,
      label: data.label,
      value: data.value,
      hint: data.hint,
      actions: _actions(data),
      flags: _flags(data),
      depth: depth,
    );
  }

  SemanticsNode? _rootSemanticsNode() {
    for (final view in RendererBinding.instance.renderViews) {
      final root = view.owner?.semanticsOwner?.rootSemanticsNode;
      if (root != null) {
        return root;
      }
    }
    return null;
  }

  Set<SceneAction> _actions(SemanticsData data) {
    final actions = <SceneAction>{};
    if (data.hasAction(SemanticsAction.tap)) {
      actions.add(SceneAction.tap);
    }
    if (data.hasAction(SemanticsAction.longPress)) {
      actions.add(SceneAction.longPress);
    }
    if (data.hasAction(SemanticsAction.scrollUp)) {
      actions.add(SceneAction.scrollUp);
    }
    if (data.hasAction(SemanticsAction.scrollDown)) {
      actions.add(SceneAction.scrollDown);
    }
    if (data.hasAction(SemanticsAction.scrollLeft)) {
      actions.add(SceneAction.scrollLeft);
    }
    if (data.hasAction(SemanticsAction.scrollRight)) {
      actions.add(SceneAction.scrollRight);
    }
    if (data.hasAction(SemanticsAction.setText)) {
      actions.add(SceneAction.setText);
    }
    return actions;
  }

  Set<SceneFlag> _flags(SemanticsData data) {
    final semanticsFlags = data.flagsCollection;
    final flags = <SceneFlag>{};
    if (semanticsFlags.isButton) {
      flags.add(SceneFlag.button);
    }
    if (semanticsFlags.isTextField) {
      flags.add(SceneFlag.textField);
    }
    if (semanticsFlags.isEnabled) {
      flags.add(SceneFlag.enabled);
    }
    if (semanticsFlags.isFocused) {
      flags.add(SceneFlag.focused);
    }
    if (semanticsFlags.isChecked) {
      flags.add(SceneFlag.checked);
    }
    if (semanticsFlags.isToggled) {
      flags.add(SceneFlag.toggled);
    }
    if (semanticsFlags.isHidden) {
      flags.add(SceneFlag.hidden);
    }
    if (semanticsFlags.isHeader) {
      flags.add(SceneFlag.header);
    }
    if (data.hasAction(SemanticsAction.scrollDown) ||
        data.hasAction(SemanticsAction.scrollUp) ||
        data.hasAction(SemanticsAction.scrollLeft) ||
        data.hasAction(SemanticsAction.scrollRight)) {
      flags.add(SceneFlag.scrollable);
    }
    return flags;
  }
}
