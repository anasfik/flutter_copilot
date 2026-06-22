import 'package:flutter/material.dart';

class CopilotDebugOverlay extends StatelessWidget {
  const CopilotDebugOverlay({
    required this.expanded,
    required this.events,
    required this.running,
    required this.status,
    required this.onToggle,
    super.key,
  });

  final bool expanded;
  final List<String> events;
  final bool running;
  final String status;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Positioned(
      top: 12,
      left: 12,
      right: 12,
      child: Material(
        elevation: 8,
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            InkWell(
              onTap: onToggle,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: <Widget>[
                    if (running)
                      const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(Icons.smart_toy_outlined,
                          size: 18, color: colors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${events.length}',
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(width: 4),
                    Icon(expanded ? Icons.expand_less : Icons.expand_more),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: events.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('No copilot events yet'),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: events.length,
                        separatorBuilder: (_, __) => const Divider(height: 12),
                        itemBuilder: (context, index) {
                          final event = events[events.length - 1 - index];
                          return Text(event, style: theme.textTheme.bodySmall);
                        },
                      ),
              ),
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
            ),
          ],
        ),
      ),
    );
  }
}
