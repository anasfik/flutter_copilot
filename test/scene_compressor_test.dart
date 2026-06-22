import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_copilot/flutter_copilot.dart';

void main() {
  test('keeps meaningful interactive nodes', () {
    final graph = SceneGraph(
      nodes: const <SceneNode>[
        SceneNode(
          id: 'n1',
          semanticsId: 1,
          rect: Rect.fromLTWH(0, 0, 100, 48),
          label: 'Settings',
          actions: <SceneAction>{SceneAction.tap},
        ),
      ],
      idToSemanticsId: const <String, int>{'n1': 1},
    );

    final compressed = const SceneCompressor().compress(graph);

    expect(compressed.nodes, hasLength(1));
    expect(compressed.nodes.single.label, 'Settings');
  });

  test('drops empty structural nodes', () {
    final graph = SceneGraph(
      nodes: const <SceneNode>[
        SceneNode(id: 'n1', semanticsId: 1, rect: Rect.fromLTWH(0, 0, 100, 48)),
        SceneNode(
            id: 'n2',
            semanticsId: 2,
            rect: Rect.fromLTWH(0, 60, 100, 48),
            label: 'Dark mode'),
      ],
      idToSemanticsId: const <String, int>{'n1': 1, 'n2': 2},
    );

    final compressed = const SceneCompressor().compress(graph);

    expect(compressed.nodes.map((node) => node.id), <String>['n2']);
  });
}
