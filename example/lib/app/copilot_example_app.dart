import 'package:flutter/material.dart';
import 'package:flutter_copilot/flutter_copilot.dart';

import '../config/theme.dart';
import '../state/app_state.dart';
import '../state/app_state_scope.dart';
import '../widgets/copilot_panel.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/tasks_screen.dart';

class CopilotExampleApp extends StatefulWidget {
  const CopilotExampleApp({super.key});

  @override
  State<CopilotExampleApp> createState() => _CopilotExampleAppState();
}

class _CopilotExampleAppState extends State<CopilotExampleApp> {
  AppState? _state;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_state != null) return;
    final controller = CopilotController.of(context);
    _state = AppState(controller)..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _state?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    if (state == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AppStateScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final colors = ColorScheme.fromSeed(
            seedColor: AppTheme.accentColors[state.accentIndex],
            brightness: state.darkMode ? Brightness.dark : Brightness.light,
          );

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'flutter_copilot demo',
            theme: (state.darkMode ? AppTheme.dark : AppTheme.light)
                .copyWith(colorScheme: colors),
            home: _CopilotScaffold(state: state),
          );
        },
      ),
    );
  }
}

class _CopilotScaffold extends StatelessWidget {
  const _CopilotScaffold({required this.state});

  final AppState state;

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
    ),
    NavigationDestination(
      icon: Icon(Icons.checklist_outlined),
      selectedIcon: Icon(Icons.checklist),
      label: 'Tasks',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  static const _titles = <String>[
    'Home',
    'Profile',
    'Tasks',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[state.navIndex]),
        actions: <Widget>[
          _CopilotFAB(state: state),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: <Widget>[
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildScreen(),
          ),
          if (state.copilotPanelOpen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: CopilotPanel(
                events: state.events,
                running: state.running,
                status: state.status,
                onClose: state.toggleCopilotPanel,
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: state.navIndex,
        onDestinationSelected: (i) => state.navIndex = i,
        destinations: _destinations,
      ),
    );
  }

  Widget _buildScreen() {
    return switch (state.navIndex) {
      0 => const HomeScreen(key: ValueKey('home')),
      1 => const ProfileScreen(key: ValueKey('profile')),
      2 => const TasksScreen(key: ValueKey('tasks')),
      3 => const SettingsScreen(key: ValueKey('settings')),
      _ => const HomeScreen(key: ValueKey('home')),
    };
  }
}

class _CopilotFAB extends StatelessWidget {
  const _CopilotFAB({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return FloatingActionButton.small(
      onPressed: state.toggleCopilotPanel,
      backgroundColor: state.running
          ? colors.primary
          : state.copilotPanelOpen
              ? colors.primaryContainer
              : colors.secondaryContainer,
      foregroundColor: state.running
          ? Colors.white
          : state.copilotPanelOpen
              ? colors.onPrimaryContainer
              : colors.onSecondaryContainer,
      heroTag: 'copilot_fab',
      child: state.running
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(
              state.copilotPanelOpen
                  ? Icons.auto_awesome
                  : Icons.auto_awesome_outlined,
              size: 20,
            ),
    );
  }
}
