import 'dart:ui';

/// Semantics action visible to the copilot.
enum SceneAction {
  /// Tap action.
  tap,

  /// Long-press action.
  longPress,

  /// Scroll up action.
  scrollUp,

  /// Scroll down action.
  scrollDown,

  /// Scroll left action.
  scrollLeft,

  /// Scroll right action.
  scrollRight,

  /// Set text action.
  setText
}

/// Semantics flag visible to the copilot.
enum SceneFlag {
  /// Button flag.
  button,

  /// Text field flag.
  textField,

  /// Enabled flag.
  enabled,

  /// Focused flag.
  focused,

  /// Checked flag.
  checked,

  /// Toggled flag.
  toggled,

  /// Hidden flag.
  hidden,

  /// Scrollable flag.
  scrollable,

  /// Header flag.
  header
}

/// Compact representation of one semantics node.
class SceneNode {
  /// Creates a scene node.
  const SceneNode({
    required this.id,
    required this.semanticsId,
    required this.rect,
    this.label = '',
    this.value = '',
    this.hint = '',
    this.actions = const <SceneAction>{},
    this.flags = const <SceneFlag>{},
    this.depth = 0,
    this.children = const <SceneNode>[],
    this.synthetic = false,
  });

  /// Public id used by LLM tools.
  final String id;

  /// Flutter semantics node id.
  final int semanticsId;

  /// Node rectangle in logical pixels.
  final Rect rect;

  /// Accessible label.
  final String label;

  /// Accessible value.
  final String value;

  /// Accessible hint.
  final String hint;

  /// Available semantics actions.
  final Set<SceneAction> actions;

  /// Semantics flags.
  final Set<SceneFlag> flags;

  /// Depth in the semantics tree.
  final int depth;

  /// Child nodes.
  final List<SceneNode> children;

  /// Whether this node was synthesized.
  final bool synthetic;

  /// Whether the node exposes any action.
  bool get isInteractive => actions.isNotEmpty;

  /// Whether the node has useful text, flags, or actions.
  bool get hasMeaning =>
      label.trim().isNotEmpty ||
      value.trim().isNotEmpty ||
      hint.trim().isNotEmpty ||
      flags.where((flag) => flag != SceneFlag.enabled).isNotEmpty ||
      actions.isNotEmpty;

  /// Whether the node is visible and non-empty.
  bool get isVisible =>
      !flags.contains(SceneFlag.hidden) && rect.width > 0 && rect.height > 0;

  /// Creates a copy with selected fields changed.
  SceneNode copyWith({
    String? id,
    int? semanticsId,
    Rect? rect,
    String? label,
    String? value,
    String? hint,
    Set<SceneAction>? actions,
    Set<SceneFlag>? flags,
    int? depth,
    List<SceneNode>? children,
    bool? synthetic,
  }) {
    return SceneNode(
      id: id ?? this.id,
      semanticsId: semanticsId ?? this.semanticsId,
      rect: rect ?? this.rect,
      label: label ?? this.label,
      value: value ?? this.value,
      hint: hint ?? this.hint,
      actions: actions ?? this.actions,
      flags: flags ?? this.flags,
      depth: depth ?? this.depth,
      children: children ?? this.children,
      synthetic: synthetic ?? this.synthetic,
    );
  }

  /// Converts this node to JSON.
  Map<String, Object?> toJson({bool includeGeometry = false}) {
    return <String, Object?>{
      'id': id,
      if (label.trim().isNotEmpty) 'label': label.trim(),
      if (value.trim().isNotEmpty) 'value': value.trim(),
      if (hint.trim().isNotEmpty) 'hint': hint.trim(),
      if (actions.isNotEmpty)
        'actions': actions.map((action) => action.name).toList(),
      if (flags.isNotEmpty) 'flags': flags.map((flag) => flag.name).toList(),
      if (synthetic) 'synthetic': true,
      if (includeGeometry)
        'rect': <String, double>{
          'left': rect.left,
          'top': rect.top,
          'width': rect.width,
          'height': rect.height,
        },
    };
  }
}
