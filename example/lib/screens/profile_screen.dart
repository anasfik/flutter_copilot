import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../state/app_state_scope.dart';
import '../widgets/section_header.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: <Widget>[
        _buildAvatarHeader(context, state),
        const SizedBox(height: 24),
        _buildPersonalInfo(context, state),
        const SizedBox(height: 20),
        _buildPreferences(context, state),
        const SizedBox(height: 20),
        _buildSubscription(context, state, colors),
        const SizedBox(height: 20),
        _buildSaveButton(context, state),
      ],
    );
  }

  Widget _buildAvatarHeader(BuildContext context, AppState state) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final name = state.displayNameController.text.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 32,
              backgroundColor: colors.primaryContainer,
              child: Text(
                name.isEmpty
                    ? 'U'
                    : name[0].toUpperCase(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    name.isEmpty ? 'User Profile' : name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.emailController.text.trim().isEmpty
                        ? 'Manage your account and preferences'
                        : state.emailController.text.trim(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfo(BuildContext context, AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeader(title: 'Personal Information'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                TextField(
                  controller: state.displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: state.emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: state.notesController,
                  decoration: const InputDecoration(
                    labelText: 'Private notes',
                    prefixIcon: Icon(Icons.notes_outlined),
                    alignLabelWithHint: true,
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferences(BuildContext context, AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeader(title: 'Preferences'),
        Card(
          child: Column(
            children: <Widget>[
              SwitchListTile(
                title: const Text('Auto-save profile'),
                subtitle: const Text('Save changes automatically'),
                value: state.autoSave,
                onChanged: (v) => state.autoSave = v,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
              const Divider(height: 1, indent: 16),
              SwitchListTile(
                title: const Text('Weekly summary'),
                subtitle: const Text('Receive a weekly activity digest'),
                value: state.weeklySummary,
                onChanged: (v) => state.weeklySummary = v,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubscription(
      BuildContext context, AppState state, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeader(title: 'Subscription'),
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
                        color: (state.premium
                                ? colors.tertiary
                                : colors.onSurfaceVariant)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        state.premium
                            ? Icons.diamond_outlined
                            : Icons.diamond_outlined,
                        size: 24,
                        color: state.premium
                            ? colors.tertiary
                            : colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            state.premium ? 'Premium' : 'Free Plan',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            state.premium
                                ? 'Advanced reports unlocked'
                                : 'Upgrade for advanced reports',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: state.premium,
                      onChanged: (v) => state.premium = v,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context, AppState state) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          final name = state.displayNameController.text.trim();
          final email = state.emailController.text.trim();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                name.isEmpty && email.isEmpty
                    ? 'Profile saved'
                    : 'Profile saved for ${name.isEmpty ? 'guest' : name}'
                        '${email.isEmpty ? '' : ' ($email)'}',
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
        icon: const Icon(Icons.save_outlined),
        label: const Text('Save Profile'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
