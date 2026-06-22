import 'dart:convert';

import 'scene_node.dart';

/// Captured UI scene sent to the model.
class SceneGraph {
  /// Creates a scene graph.
  SceneGraph({
    required this.nodes,
    required this.idToSemanticsId,
    DateTime? capturedAt,
  }) : capturedAt = capturedAt ?? DateTime.now();

  /// Visible and meaningful scene nodes.
  final List<SceneNode> nodes;

  /// Map from public node ids to Flutter semantics ids.
  final Map<String, int> idToSemanticsId;

  /// Capture timestamp.
  final DateTime capturedAt;

  /// Returns the Flutter semantics id for [publicId].
  int? semanticsIdFor(String publicId) => idToSemanticsId[publicId];

  /// Converts this scene to JSON.
  Map<String, Object?> toJson({bool includeGeometry = false}) {
    return <String, Object?>{
      'captured_at': capturedAt.toIso8601String(),
      'nodes': nodes
          .map((node) => node.toJson(includeGeometry: includeGeometry))
          .toList(),
    };
  }

  /// Compact JSON representation used in prompts.
  String toCompactJson() => jsonEncode(toJson());
}
