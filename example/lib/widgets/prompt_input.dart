import 'package:flutter/material.dart';

class PromptInput extends StatelessWidget {
  const PromptInput({
    required this.controller,
    required this.running,
    required this.samplePrompts,
    required this.onRun,
    required this.onPromptSelected,
    super.key,
  });

  final TextEditingController controller;
  final bool running;
  final List<String> samplePrompts;
  final VoidCallback onRun;
  final ValueChanged<String> onPromptSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.auto_awesome,
                      size: 20, color: colors.primary),
                ),
                const SizedBox(width: 12),
                Text(
                  'Ask Copilot',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              enabled: !running,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'What should the copilot do?',
                hintStyle: TextStyle(color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
                suffixIcon: running
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Try these',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final prompt in samplePrompts)
                  _SampleChip(
                    label: prompt,
                    onTap: running ? null : () => onPromptSelected(prompt),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: running ? null : onRun,
                icon: running
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(running ? 'Copilot is working...' : 'Run Copilot'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SampleChip extends StatelessWidget {
  const _SampleChip({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: onTap != null
              ? colors.primaryContainer.withValues(alpha: 0.4)
              : colors.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: onTap != null
                ? colors.primary.withValues(alpha: 0.3)
                : colors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: onTap != null
                    ? colors.primary
                    : colors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
        ),
      ),
    );
  }
}
