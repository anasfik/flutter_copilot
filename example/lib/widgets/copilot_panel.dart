import 'package:flutter/material.dart';

class CopilotPanel extends StatelessWidget {
  const CopilotPanel({
    required this.events,
    required this.running,
    required this.status,
    required this.onClose,
    super.key,
  });

  final List<String> events;
  final bool running;
  final String status;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.surface,
      elevation: 4,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildHeader(context, colors),
          if (events.isEmpty && !running) _buildEmptyState(context, colors),
          if (events.isNotEmpty || running) _buildEventList(context, colors),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: <Widget>[
          if (running)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(Icons.auto_awesome, size: 20, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Copilot',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (events.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${events.length}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: onClose,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.auto_awesome_outlined,
            size: 32,
            color: colors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'No copilot activity yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Run a prompt to see the agent at work',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(BuildContext context, ColorScheme colors) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 240),
      child: ListView.separated(
        shrinkWrap: true,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final event = events[events.length - 1 - index];
          final isFirst = index == 0;
          return _EventTile(text: event, highlighted: isFirst);
        },
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.text, this.highlighted = false});

  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    IconData icon;
    Color iconColor;

    if (text.startsWith('Started')) {
      icon = Icons.play_arrow_rounded;
      iconColor = colors.primary;
    } else if (text.startsWith('Finished')) {
      icon = Icons.check_circle_outline;
      iconColor = colors.tertiary;
    } else if (text.contains('Confirmation')) {
      icon = Icons.privacy_tip_outlined;
      iconColor = colors.tertiary;
    } else if (text.startsWith('Failed') || text.contains('failed')) {
      icon = Icons.error_outline;
      iconColor = colors.error;
    } else if (text.contains('tap') ||
        text.contains('scroll') ||
        text.contains('type') ||
        text.contains('replace_text') ||
        text.contains('slider') ||
        text.contains('drag')) {
      icon = Icons.touch_app_outlined;
      iconColor = colors.secondary;
    } else if (text.contains('LLM')) {
      icon = Icons.psychology_outlined;
      iconColor = colors.primary;
    } else {
      icon = Icons.circle_outlined;
      iconColor = colors.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted
            ? colors.primaryContainer.withValues(alpha: 0.3)
            : colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight:
                        highlighted ? FontWeight.w500 : FontWeight.normal,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
