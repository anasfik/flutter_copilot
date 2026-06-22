import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../state/app_state_scope.dart';
import '../widgets/prompt_input.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final completedTasks = state.tasks.where((t) => t.done).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: <Widget>[
        _buildHeroBanner(context),
        const SizedBox(height: 20),
        _buildQuickStats(context, state, completedTasks),
        const SizedBox(height: 20),
        PromptInput(
          controller: state.promptController,
          running: state.running,
          samplePrompts: state.prompts,
          onRun: state.runCopilot,
          onPromptSelected: state.setPrompt,
        ),
        const SizedBox(height: 20),
        _buildQuickActions(context, state),
      ],
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            colors.primary,
            colors.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child:
                const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'flutter_copilot',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'AI agent that autonomously navigates your Flutter app UI through the semantics tree.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(
      BuildContext context, AppState state, int completedTasks) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeader(title: 'Overview', subtitle: 'Demo app at a glance'),
        const SizedBox(height: 4),
        Row(
          children: <Widget>[
            Expanded(
              child: StatCard(
                icon: Icons.check_circle_outline,
                label: 'Completed',
                value: '$completedTasks',
                color: colors.tertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.pending_outlined,
                label: 'Active',
                value: '${state.tasks.length - completedTasks}',
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.shopping_cart_outlined,
                label: 'Cart',
                value: '${state.cartCount}',
                color: colors.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, AppState state) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeader(title: 'Quick Actions'),
        Row(
          children: <Widget>[
            Expanded(
              child: _ActionCard(
                icon: Icons.person_outline,
                label: 'Profile',
                onTap: () => state.navIndex = 1,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.checklist_outlined,
                label: 'Tasks',
                onTap: () => state.navIndex = 2,
                color: colors.tertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () => state.navIndex = 3,
                color: colors.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
