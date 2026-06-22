import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.cartCount,
    required this.darkMode,
    required this.promptController,
    required this.running,
    required this.samplePrompts,
    required this.onAddStarterKit,
    required this.onClearCart,
    required this.onOpenProfile,
    required this.onOpenSettings,
    required this.onRunCopilot,
    super.key,
  });

  final int cartCount;
  final bool darkMode;
  final TextEditingController promptController;
  final bool running;
  final List<String> samplePrompts;
  final VoidCallback onAddStarterKit;
  final VoidCallback onClearCart;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenSettings;
  final VoidCallback onRunCopilot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text('Copilot demo', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Enable dark mode', style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(darkMode ? 'Dark mode is on' : 'Dark mode is off'),
                const SizedBox(height: 16),
                TextField(
                  controller: promptController,
                  enabled: !running,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Prompt',
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final prompt in samplePrompts)
                      ActionChip(
                        label: Text(prompt),
                        onPressed: running
                            ? null
                            : () => promptController.text = prompt,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: running ? null : onRunCopilot,
                      icon: running
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(running ? 'Copilot running' : 'Ask copilot'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onOpenProfile,
                      icon: const Icon(Icons.person),
                      label: const Text('Open profile'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onOpenSettings,
                      icon: const Icon(Icons.settings),
                      label: const Text('Open settings'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Starter kit'),
            subtitle:
                Text('$cartCount item${cartCount == 1 ? '' : 's'} in cart'),
            trailing: Wrap(
              spacing: 8,
              children: <Widget>[
                IconButton(
                  tooltip: 'Add starter kit',
                  onPressed: onAddStarterKit,
                  icon: const Icon(Icons.add_shopping_cart),
                ),
                IconButton(
                  tooltip: 'Clear cart',
                  onPressed: cartCount == 0 ? null : onClearCart,
                  icon: const Icon(Icons.remove_shopping_cart),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
