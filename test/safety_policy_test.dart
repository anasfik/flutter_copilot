import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_copilot/flutter_copilot.dart';

void main() {
  test('blocks destructive action labels', () {
    final scene = SceneGraph(
      nodes: const <SceneNode>[
        SceneNode(
          id: 'n1',
          semanticsId: 1,
          rect: Rect.fromLTWH(0, 0, 100, 48),
          label: 'Delete account',
          actions: <SceneAction>{SceneAction.tap},
        ),
      ],
      idToSemanticsId: const <String, int>{'n1': 1},
    );

    final decision =
        CopilotSafetyPolicy.defaults.evaluate(const TapAction('n1'), scene);

    expect(decision.allowed, isFalse);
    expect(decision.requiresConfirmation, isTrue);
  });

  test('matches custom string labels case-insensitively', () {
    final scene = SceneGraph(
      nodes: const <SceneNode>[
        SceneNode(
          id: 'n1',
          semanticsId: 1,
          rect: Rect.fromLTWH(0, 0, 100, 48),
          label: 'Publish',
          actions: <SceneAction>{SceneAction.tap},
        ),
      ],
      idToSemanticsId: const <String, int>{'n1': 1},
    );

    final decision = CopilotSafetyPolicy(
      blockedLabels: const <Pattern>['publish'],
    ).evaluate(const TapAction('n1'), scene);

    expect(decision.allowed, isFalse);
  });

  test('supports developer declared careful labels', () {
    final scene = SceneGraph(
      nodes: const <SceneNode>[
        SceneNode(
          id: 'n1',
          semanticsId: 1,
          rect: Rect.fromLTWH(0, 0, 100, 48),
          label: 'Export customer data',
          actions: <SceneAction>{SceneAction.tap},
        ),
      ],
      idToSemanticsId: const <String, int>{'n1': 1},
    );

    final decision = CopilotSafetyPolicy(
      carefulLabels: const <Pattern>['customer data'],
    ).evaluate(const TapAction('n1'), scene);

    expect(decision.allowed, isFalse);
    expect(decision.requiresConfirmation, isTrue);
  });

  test('denied labels cannot be bypassed by destructive access', () {
    final scene = SceneGraph(
      nodes: const <SceneNode>[
        SceneNode(
          id: 'n1',
          semanticsId: 1,
          rect: Rect.fromLTWH(0, 0, 100, 48),
          label: 'Production billing admin',
          actions: <SceneAction>{SceneAction.tap},
        ),
      ],
      idToSemanticsId: const <String, int>{'n1': 1},
    );

    final decision = CopilotSafetyPolicy(
      doNotTouchLabels: const <Pattern>['production billing'],
      allowDestructiveActions: true,
    ).evaluate(const TapAction('n1'), scene);

    expect(decision.allowed, isFalse);
    expect(decision.requiresConfirmation, isFalse);
  });

  test('blocks destructive labels for gesture actions', () {
    final scene = SceneGraph(
      nodes: const <SceneNode>[
        SceneNode(
          id: 'n1',
          semanticsId: 1,
          rect: Rect.fromLTWH(0, 0, 100, 48),
          label: 'Delete account',
          actions: <SceneAction>{SceneAction.longPress},
        ),
      ],
      idToSemanticsId: const <String, int>{'n1': 1},
    );

    final decision = CopilotSafetyPolicy.defaults
        .evaluate(const LongPressAction('n1'), scene);

    expect(decision.allowed, isFalse);
  });
}
