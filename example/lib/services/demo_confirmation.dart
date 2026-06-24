import 'package:flutter/material.dart';
import 'package:flutter_copilot/flutter_copilot.dart';

final demoNavigatorKey = GlobalKey<NavigatorState>();

Future<bool> confirmCopilotAction(CopilotConfirmationRequest request) async {
  final context = demoNavigatorKey.currentContext;
  if (context == null) {
    return false;
  }

  final node = request.node;
  final label = node == null
      ? null
      : [node.label, node.value, node.hint]
          .where((part) => part.trim().isNotEmpty)
          .join(' / ');

  final approved = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.privacy_tip_outlined),
      title: const Text('Copilot wants approval'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(request.reason),
          if (label != null && label.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Target: $label',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Deny'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Approve'),
        ),
      ],
    ),
  );

  return approved ?? false;
}
