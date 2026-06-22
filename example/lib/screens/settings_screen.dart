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
                Row(
                  children: <Widget>[
                    Icon(
                      state.darkMode
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Dark mode',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            state.darkMode
                                ? 'Dark theme active'
                                : 'Light theme active',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: state.darkMode,
                      onChanged: (v) => state.darkMode = v,
                    ),
                  ],
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
          child: SwitchListTile(
            title: const Text('Push notifications'),
            subtitle: const Text('Receive product and task alerts'),
            value: state.notifications,
            onChanged: (v) => state.notifications = v,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
                      child:
                          Icon(Icons.warning_amber_rounded, color: colors.error),
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
                      side: BorderSide(color: colors.error.withValues(alpha: 0.5)),
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
    );
  }
}
