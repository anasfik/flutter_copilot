import 'dart:async';

import 'package:flutter/material.dart' hide ScrollAction;
import 'package:flutter_copilot/flutter_copilot.dart';

import '../data/sample_prompts.dart';
import '../models/demo_task.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/tasks_screen.dart';
import '../utils/copilot_event_text.dart';
import '../widgets/copilot_debug_overlay.dart';

class CopilotExampleApp extends StatefulWidget {
  const CopilotExampleApp({super.key});

  @override
  State<CopilotExampleApp> createState() => _CopilotExampleAppState();
}

class _CopilotExampleAppState extends State<CopilotExampleApp> {
  bool _darkMode = false;
  bool _notifications = false;
  bool _compactMode = false;
  bool _autoSave = true;
  bool _debugExpanded = false;
  bool _running = false;
  bool _premium = false;
  bool _weeklySummary = false;
  int _index = 0;
  int _accentIndex = 0;
  int _cartCount = 0;
  String _taskFilter = 'All';
  String _status = 'Ready';
  final _events = <String>[];
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  final _promptController =
      TextEditingController(text: 'Open settings and enable dark mode');
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();
  final _tasks = <DemoTask>[
    DemoTask('Review onboarding flow', done: true),
    DemoTask('Write release notes'),
    DemoTask('Test checkout error state'),
    DemoTask('Invite Morgan to workspace'),
    DemoTask('Archive old invoices'),
  ];
  CopilotController? _controller;
  StreamSubscription<CopilotEvent>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextController = CopilotController.of(context);
    if (_controller == nextController) {
      return;
    }
    _subscription?.cancel();
    _controller = nextController;
    _subscription = nextController.events.listen((event) {
      if (!mounted) {
        return;
      }
      setState(() => _events.insert(0, describeEvent(event)));
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _promptController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runCopilot() async {
    final controller = _controller;
    if (controller == null || _running) {
      return;
    }

    setState(() {
      _running = true;
      _status = 'Running';
      _events.clear();
    });

    final prompt = _promptController.text.trim();
    final result = await controller.run(
      prompt.isEmpty ? 'Open settings and enable dark mode' : prompt,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _running = false;
      _status = describeResult(result);
    });
    _showRunResult(result);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: <Color>[
        Colors.teal,
        Colors.indigo,
        Colors.deepOrange
      ][_accentIndex],
      brightness: _darkMode ? Brightness.dark : Brightness.light,
    );

    return MaterialApp(
      scaffoldMessengerKey: _messengerKey,
      title: 'flutter_copilot example',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('flutter_copilot example')),
        body: Stack(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: _debugExpanded ? 332 : 68),
              child: IndexedStack(
                index: _index,
                children: <Widget>[
                  HomeScreen(
                    cartCount: _cartCount,
                    darkMode: _darkMode,
                    promptController: _promptController,
                    running: _running,
                    samplePrompts: samplePrompts,
                    onAddStarterKit: () => setState(() => _cartCount++),
                    onClearCart: () => setState(() => _cartCount = 0),
                    onOpenProfile: () => setState(() => _index = 1),
                    onOpenSettings: () => setState(() => _index = 3),
                    onRunCopilot: _runCopilot,
                  ),
                  ProfileScreen(
                    autoSave: _autoSave,
                    displayNameController: _displayNameController,
                    emailController: _emailController,
                    notesController: _notesController,
                    premium: _premium,
                    weeklySummary: _weeklySummary,
                    onAutoSaveChanged: (value) =>
                        setState(() => _autoSave = value),
                    onPremiumChanged: (value) =>
                        setState(() => _premium = value),
                    onSave: () => setState(() {
                      final name = _displayNameController.text.trim();
                      _status =
                          'Profile saved for ${name.isEmpty ? 'guest' : name}';
                    }),
                    onWeeklySummaryChanged: (value) =>
                        setState(() => _weeklySummary = value),
                  ),
                  TasksScreen(
                    filter: _taskFilter,
                    searchController: _searchController,
                    tasks: _tasks,
                    onAddTask: () => setState(() {
                      _tasks.add(DemoTask('New task ${_tasks.length + 1}'));
                    }),
                    onFilterChanged: (value) =>
                        setState(() => _taskFilter = value),
                    onTaskChanged: (task, value) =>
                        setState(() => task.done = value),
                  ),
                  SettingsScreen(
                    accentIndex: _accentIndex,
                    compactMode: _compactMode,
                    darkMode: _darkMode,
                    notifications: _notifications,
                    onAccentChanged: (value) =>
                        setState(() => _accentIndex = value),
                    onCompactModeChanged: (value) =>
                        setState(() => _compactMode = value),
                    onDarkModeChanged: (value) =>
                        setState(() => _darkMode = value),
                    onNotificationsChanged: (value) =>
                        setState(() => _notifications = value),
                    onResetDemo: () => _confirmReset(context),
                  ),
                ],
              ),
            ),
            CopilotDebugOverlay(
              expanded: _debugExpanded,
              events: _events,
              running: _running,
              status: _status,
              onToggle: () => setState(() => _debugExpanded = !_debugExpanded),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (index) => setState(() => _index = index),
          destinations: const <NavigationDestination>[
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
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset demo data'),
        content:
            const Text('This clears profile fields, tasks, and cart items.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel reset'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm reset'),
          ),
        ],
      ),
    );
    if (shouldReset != true || !mounted) {
      return;
    }
    setState(() {
      _displayNameController.clear();
      _emailController.clear();
      _notesController.clear();
      _searchController.clear();
      _tasks
        ..clear()
        ..addAll(<DemoTask>[
          DemoTask('Review onboarding flow', done: true),
          DemoTask('Write release notes'),
          DemoTask('Test checkout error state'),
        ]);
      _cartCount = 0;
      _premium = false;
      _weeklySummary = false;
      _status = 'Demo data reset';
    });
  }

  void _showRunResult(CopilotRunResult result) {
    final messenger = _messengerKey.currentState;
    if (messenger == null) {
      return;
    }
    messenger.clearSnackBars();
    final failed = result is CopilotFailed || result is CopilotMaxStepsExceeded;
    final colors = _messengerKey.currentContext == null
        ? null
        : Theme.of(_messengerKey.currentContext!).colorScheme;
    messenger.showSnackBar(
      SnackBar(
        content: Text(describeResult(result)),
        backgroundColor: failed ? colors?.error : colors?.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
