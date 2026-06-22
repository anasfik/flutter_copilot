import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    required this.autoSave,
    required this.displayNameController,
    required this.emailController,
    required this.notesController,
    required this.premium,
    required this.weeklySummary,
    required this.onAutoSaveChanged,
    required this.onPremiumChanged,
    required this.onSave,
    required this.onWeeklySummaryChanged,
    super.key,
  });

  final bool autoSave;
  final TextEditingController displayNameController;
  final TextEditingController emailController;
  final TextEditingController notesController;
  final bool premium;
  final bool weeklySummary;
  final ValueChanged<bool> onAutoSaveChanged;
  final ValueChanged<bool> onPremiumChanged;
  final VoidCallback onSave;
  final ValueChanged<bool> onWeeklySummaryChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text('Profile', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        TextField(
          controller: displayNameController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Display name',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: emailController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Email address',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: notesController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Private notes',
          ),
          minLines: 2,
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Auto-save profile'),
          value: autoSave,
          onChanged: onAutoSaveChanged,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Weekly summary email'),
          value: weeklySummary,
          onChanged: onWeeklySummaryChanged,
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Upgrade to premium'),
          subtitle: const Text('Unlocks advanced reports'),
          value: premium,
          onChanged: (value) => onPremiumChanged(value ?? false),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.save),
          label: const Text('Save profile'),
        ),
      ],
    );
  }
}
