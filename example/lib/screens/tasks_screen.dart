import 'package:flutter/material.dart';

import '../models/demo_task.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({
    required this.filter,
    required this.searchController,
    required this.tasks,
    required this.onAddTask,
    required this.onFilterChanged,
    required this.onTaskChanged,
    super.key,
  });

  final String filter;
  final TextEditingController searchController;
  final List<DemoTask> tasks;
  final VoidCallback onAddTask;
  final ValueChanged<String> onFilterChanged;
  final void Function(DemoTask task, bool value) onTaskChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleTasks = tasks.where((task) {
      return switch (filter) {
        'Active' => !task.done,
        'Done' => task.done,
        _ => true,
      };
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text('Tasks', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        TextField(
          controller: searchController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Search tasks',
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const <ButtonSegment<String>>[
            ButtonSegment(value: 'All', label: Text('All')),
            ButtonSegment(value: 'Active', label: Text('Active')),
            ButtonSegment(value: 'Done', label: Text('Done')),
          ],
          selected: <String>{filter},
          onSelectionChanged: (values) => onFilterChanged(values.first),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onAddTask,
          icon: const Icon(Icons.add),
          label: const Text('Add task'),
        ),
        const SizedBox(height: 12),
        for (final task in visibleTasks)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(task.title),
            subtitle: Text(task.done ? 'Done' : 'Active'),
            value: task.done,
            onChanged: (value) => onTaskChanged(task, value ?? false),
          ),
      ],
    );
  }
}
