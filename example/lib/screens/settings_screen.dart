import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../state/app_state.dart';
import '../state/app_state_scope.dart';
import '../widgets/section_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: <Widget>[
        _buildAppearance(context, state),
        const SizedBox(height: 20),
        _buildNotifications(context, state),
        const SizedBox(height: 20),
        _buildDangerZone(context, state),
      ],
    );
  }

  Widget _buildAppearance(BuildContext context, AppState state) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeader(title: 'Appearance'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(
                    state.darkMode
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    color: colors.primary,
                  ),
                  title: const Text('Dark mode'),
                  subtitle: Text(
                    state.darkMode ? 'Dark theme active' : 'Light theme active',
                  ),
                  value: state.darkMode,
                  onChanged: (v) => state.darkMode = v,
                ),
                const SizedBox(height: 20),
                Text(
                  'Accent color',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    for (var i = 0; i < AppTheme.accentColors.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      _AccentDot(
                        color: AppTheme.accentColors[i],
                        label: AppTheme.accentNames[i],
                        selected: state.accentIndex == i,
                        onTap: () => state.accentIndex = i,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Compact mode'),
                  subtitle: const Text('Denser lists and controls'),
                  value: state.compactMode,
                  onChanged: (v) => state.compactMode = v,
                ),
                const SizedBox(height: 12),
                Text(
                  'Font scale',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                Semantics(
                  label: 'Font scale',
                  value: '${(state.fontScale * 100).round()} percent',
                  child: Slider(
                    value: state.fontScale,
                    min: 0.8,
                    max: 1.4,
                    divisions: 6,
                    label: '${(state.fontScale * 100).round()}%',
                    onChanged: (v) => state.fontScale = v,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotifications(BuildContext context, AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeader(title: 'Notifications'),
        Card(
          child: Column(
            children: <Widget>[
              SwitchListTile(
                title: const Text('Push notifications'),
                subtitle: const Text('Receive product and task alerts'),
                value: state.notifications,
                onChanged: (v) => state.notifications = v,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
              const Divider(height: 1, indent: 16),
              SwitchListTile(
                title: const Text('Weekly email'),
                subtitle: const Text('Send a weekly summary email'),
                value: state.weeklySummary,
                onChanged: (v) => state.weeklySummary = v,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZone(BuildContext context, AppState state) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: 'Danger Zone',
          subtitle: 'Destructive actions require confirmation',
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.warning_amber_rounded,
                          color: colors.error),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Reset demo data',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Clears all profile fields, tasks, and cart',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmReset(context, state),
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reset Everything'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.error,
                      side: BorderSide(
                          color: colors.error.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmReset(BuildContext context, AppState state) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: const Text('Reset demo data'),
        content: const Text(
          'This will clear all profile fields, tasks, and cart items. This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (shouldReset == true && context.mounted) {
      state.resetDemo();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Demo data has been reset'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}

class _AccentDot extends StatelessWidget {
  const _AccentDot({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        label: '$label accent color${selected ? ' (selected)' : ''}',
        button: true,
        selected: selected,
        child: Column(
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: selected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.onSurface,
                        width: 3,
                      )
                    : null,
                boxShadow: selected
                    ? <BoxShadow>[
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
