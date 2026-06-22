import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../state/app_state_scope.dart';
import '../widgets/section_header.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: <Widget>[
        _buildTaskStats(context, state),
        const SizedBox(height: 20),
        _buildTaskList(context, state),
      ],
    );
  }

  Widget _buildTaskStats(BuildContext context, AppState state) {
    final colors = Theme.of(context).colorScheme;
    final completed = state.tasks.where((t) => t.done).length;
    final active = state.tasks.length - completed;
    final progress =
        state.tasks.isEmpty ? 0.0 : completed / state.tasks.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.analytics_outlined,
                      size: 24, color: colors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Task Progress',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$completed of ${state.tasks.length} completed',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: colors.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                _MiniStat(
                  label: 'Active',
                  value: '$active',
                  color: colors.primary,
                ),
                const SizedBox(width: 24),
                _MiniStat(
                  label: 'Done',
                  value: '$completed',
                  color: colors.tertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, AppState state) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: 'Tasks',
          subtitle: '${state.visibleTasks.length} tasks',
          trailing: SegmentedButton<String>(
            segments: const <ButtonSegment<String>>[
              ButtonSegment(value: 'All', label: Text('All')),
              ButtonSegment(value: 'Active', label: Text('Active')),
              ButtonSegment(value: 'Done', label: Text('Done')),
            ],
            selected: <String>{state.taskFilter},
            onSelectionChanged: (values) =>
                state.taskFilter = values.first,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Card(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: state.searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              if (state.visibleTasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: <Widget>[
                      Icon(Icons.checklist_outlined,
                          size: 40,
                          color: colors.onSurfaceVariant.withValues(alpha: 0.3)),
                      const SizedBox(height: 8),
                      Text(
                        'No tasks match this filter',
                        style: TextStyle(
                            color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                )
              else
                for (final task in state.visibleTasks)
                  _TaskTile(
                    task: task,
                    onToggle: () => state.toggleTask(task),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: state.addTask,
            icon: const Icon(Icons.add),
            label: const Text('Add Task'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $value',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.onToggle});

  final dynamic task;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDone = task.done as bool;

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDone ? colors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: isDone
                    ? null
                    : Border.all(color: colors.outline, width: 2),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                task.title as String,
                style: TextStyle(
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  color: isDone ? colors.onSurfaceVariant : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
