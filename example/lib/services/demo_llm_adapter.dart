import 'dart:convert';

import 'package:flutter_copilot/flutter_copilot.dart';

class DemoLlmAdapter implements LlmAdapter {
  DemoLlmAdapter();

  @override
  Future<LlmResponse> complete({
    required List<LlmMessage> messages,
    required List<LlmTool> tools,
  }) async {
    final goal = _goalFrom(messages);
    final step = _stepFrom(messages);
    final nodes = _nodesFrom(messages);

    LlmToolCall? call;
    if (goal.contains('dark mode')) {
      call = _sequence(step, <LlmToolCall?>[
        _tap(nodes, 'Settings'),
        _tap(nodes, 'Dark mode'),
        _done('Dark mode enabled.'),
      ]);
    } else if (goal.contains('display name') || goal.contains('profile')) {
      call = _sequence(step, <LlmToolCall?>[
        _tap(nodes, 'Profile'),
        _replace(nodes, 'Display name', 'Alex Rivera'),
        _replace(nodes, 'Email address', 'alex@example.com'),
        _tap(nodes, 'Weekly summary'),
        _tap(nodes, 'Save Profile'),
        _done('Profile updated.'),
      ]);
    } else if (goal.contains('release notes')) {
      call = _sequence(step, <LlmToolCall?>[
        _tap(nodes, 'Tasks'),
        _tap(nodes, 'Write release notes'),
        _done('Release notes task marked done.'),
      ]);
    } else if (goal.contains('active tasks')) {
      call = _sequence(step, <LlmToolCall?>[
        _tap(nodes, 'Tasks'),
        _tap(nodes, 'Active'),
        _done('Active task filter selected.'),
      ]);
    } else if (goal.contains('notifications')) {
      call = _sequence(step, <LlmToolCall?>[
        _tap(nodes, 'Settings'),
        _tap(nodes, 'Push notifications'),
        _tap(nodes, 'Weekly email'),
        _done('Notifications enabled.'),
      ]);
    } else if (goal.contains('font') || goal.contains('slider')) {
      call = _sequence(step, <LlmToolCall?>[
        _tap(nodes, 'Settings'),
        _slider(nodes, 'Font scale', 0.8),
        _done('Font scale adjusted.'),
      ]);
    } else if (goal.contains('delete') || goal.contains('reset')) {
      call = _sequence(step, <LlmToolCall?>[
        _tap(nodes, 'Settings'),
        _confirm('Resetting demo data is destructive.'),
        _tap(nodes, 'Reset Everything'),
        _tap(nodes, 'Reset'),
        _done('Demo data reset.'),
      ]);
    } else {
      call = _sequence(step, <LlmToolCall?>[
        _tap(nodes, 'Settings'),
        _done('Opened settings.'),
      ]);
    }

    return LlmResponse(toolCall: call ?? _done('Demo plan completed.'));
  }

  int _stepFrom(List<LlmMessage> messages) {
    return messages
        .where((message) =>
            message.role == LlmRole.assistant &&
            message.content.startsWith('Selected actions JSON:'))
        .length;
  }

  LlmToolCall? _sequence(int step, List<LlmToolCall?> calls) {
    if (step >= calls.length) {
      return _done('Demo plan completed.');
    }
    return calls[step];
  }

  String _goalFrom(List<LlmMessage> messages) {
    for (final message in messages) {
      if (message.role == LlmRole.user &&
          message.content.startsWith('Goal: ')) {
        return message.content.substring(6).trim().toLowerCase();
      }
    }
    return '';
  }

  List<Map<String, Object?>> _nodesFrom(List<LlmMessage> messages) {
    for (final message in messages.reversed) {
      const marker = 'Current screen JSON:\n';
      if (message.role == LlmRole.user && message.content.startsWith(marker)) {
        final decoded =
            jsonDecode(message.content.substring(marker.length).trim());
        final nodes = (decoded as Map<String, Object?>)['nodes'];
        if (nodes is List) {
          return nodes.cast<Map<String, Object?>>();
        }
      }
    }
    return const <Map<String, Object?>>[];
  }

  String? _idFor(List<Map<String, Object?>> nodes, String text) {
    final lower = text.toLowerCase();
    String? fallback;
    for (final node in nodes) {
      final haystack = '${node['label'] ?? ''} ${node['value'] ?? ''} '
              '${node['hint'] ?? ''}'
          .toLowerCase();
      if (haystack.contains(lower)) {
        final id = node['id'] as String?;
        final actions = node['actions'];
        if (actions is List && actions.contains('tap')) {
          return id;
        }
        fallback ??= id;
      }
    }
    return fallback;
  }

  LlmToolCall? _tap(List<Map<String, Object?>> nodes, String label) {
    final id = _idFor(nodes, label);
    if (id == null) {
      return null;
    }
    return LlmToolCall(
      id: 'tap_$id',
      name: 'tap',
      arguments: <String, Object?>{'id': id},
    );
  }

  LlmToolCall? _replace(
      List<Map<String, Object?>> nodes, String label, String text) {
    final id = _idFor(nodes, label);
    if (id == null) {
      return null;
    }
    return LlmToolCall(
      id: 'replace_$id',
      name: 'replace_text',
      arguments: <String, Object?>{'id': id, 'text': text},
    );
  }

  LlmToolCall? _slider(
      List<Map<String, Object?>> nodes, String label, double value) {
    final id = _idFor(nodes, label);
    if (id == null) {
      return null;
    }
    return LlmToolCall(
      id: 'slider_$id',
      name: 'slider_to_value',
      arguments: <String, Object?>{'id': id, 'value': value},
    );
  }

  LlmToolCall _confirm(String reason) => LlmToolCall(
        id: 'confirm',
        name: 'request_confirmation',
        arguments: <String, Object?>{'reason': reason},
      );

  LlmToolCall _done(String summary) => LlmToolCall(
        id: 'done',
        name: 'done',
        arguments: <String, Object?>{'summary': summary},
      );
}
