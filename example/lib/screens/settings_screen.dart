import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.accentIndex,
    required this.compactMode,
    required this.darkMode,
    required this.notifications,
    required this.onAccentChanged,
    required this.onCompactModeChanged,
    required this.onDarkModeChanged,
    required this.onNotificationsChanged,
    required this.onResetDemo,
    super.key,
  });

  final int accentIndex;
  final bool compactMode;
  final bool darkMode;
  final bool notifications;
  final ValueChanged<int> onAccentChanged;
  final ValueChanged<bool> onCompactModeChanged;
  final ValueChanged<bool> onDarkModeChanged;
  final ValueChanged<bool> onNotificationsChanged;
  final VoidCallback onResetDemo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text('Settings', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        Semantics(
          label: 'Dark mode',
          value: darkMode ? 'On' : 'Off',
          toggled: darkMode,
          button: true,
          onTap: () => onDarkModeChanged(!darkMode),
          child: ExcludeSemantics(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dark mode'),
              subtitle: Text(darkMode
                  ? 'Use the dark color scheme'
                  : 'Use the light color scheme'),
              value: darkMode,
              onChanged: onDarkModeChanged,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Notifications'),
          subtitle: const Text('Receive product and task alerts'),
          value: notifications,
          onChanged: onNotificationsChanged,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Compact mode'),
          subtitle: const Text('Use denser lists and controls'),
          value: compactMode,
          onChanged: onCompactModeChanged,
        ),
        const SizedBox(height: 12),
        Text('Accent color', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const <ButtonSegment<int>>[
            ButtonSegment(value: 0, label: Text('Teal')),
            ButtonSegment(value: 1, label: Text('Indigo')),
            ButtonSegment(value: 2, label: Text('Orange')),
          ],
          selected: <int>{accentIndex},
          onSelectionChanged: (values) => onAccentChanged(values.first),
        ),
        const SizedBox(height: 24),
        Text('Danger zone', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onResetDemo,
          icon: const Icon(Icons.restart_alt),
          label: const Text('Reset demo data'),
        ),
      ],
    );
  }
}
