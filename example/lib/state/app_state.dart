import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_copilot/flutter_copilot.dart';

import '../data/sample_prompts.dart';
import '../models/demo_task.dart';
import '../utils/copilot_event_text.dart';

class AppState extends ChangeNotifier {
  AppState(this._copilotController) {
    _subscription = _copilotController.events.listen((event) {
      _events.insert(0, describeEvent(event));
      notifyListeners();
    });
  }

  final CopilotController _copilotController;
  StreamSubscription<CopilotEvent>? _subscription;

  int _navIndex = 0;
  bool _darkMode = false;
  bool _notifications = true;
  bool _compactMode = false;
  bool _autoSave = true;
  bool _weeklySummary = true;
  bool _premium = false;
  int _accentIndex = 0;
  int _cartCount = 0;
  bool _running = false;
  bool _copilotPanelOpen = false;
  String _status = 'Ready';
  String _taskFilter = 'All';
  final _events = <String>[];
  final _tasks = <DemoTask>[
    DemoTask('Review onboarding flow', done: true),
    DemoTask('Write release notes'),
    DemoTask('Test checkout error state'),
    DemoTask('Invite Morgan to workspace'),
    DemoTask('Archive old invoices'),
  ];
  final promptController =
      TextEditingController(text: 'Open settings and enable dark mode');
  final displayNameController = TextEditingController();
  final emailController = TextEditingController();
  final notesController = TextEditingController();
  final searchController = TextEditingController();

  int get navIndex => _navIndex;
  bool get darkMode => _darkMode;
  bool get notifications => _notifications;
  bool get compactMode => _compactMode;
  bool get autoSave => _autoSave;
  bool get weeklySummary => _weeklySummary;
  bool get premium => _premium;
  int get accentIndex => _accentIndex;
  int get cartCount => _cartCount;
  bool get running => _running;
  bool get copilotPanelOpen => _copilotPanelOpen;
  String get status => _status;
  String get taskFilter => _taskFilter;
  List<String> get events => List.unmodifiable(_events);
  List<DemoTask> get tasks => List.unmodifiable(_tasks);
  List<String> get prompts => samplePrompts;

  List<DemoTask> get visibleTasks => _tasks.where((task) {
        return switch (_taskFilter) {
          'Active' => !task.done,
          'Done' => task.done,
          _ => true,
        };
      }).toList();

  set navIndex(int value) {
    _navIndex = value;
    notifyListeners();
  }

  set darkMode(bool value) {
    _darkMode = value;
    notifyListeners();
  }

  set notifications(bool value) {
    _notifications = value;
    notifyListeners();
  }

  set compactMode(bool value) {
    _compactMode = value;
    notifyListeners();
  }

  set autoSave(bool value) {
    _autoSave = value;
    notifyListeners();
  }

  set weeklySummary(bool value) {
    _weeklySummary = value;
    notifyListeners();
  }

  set premium(bool value) {
    _premium = value;
    notifyListeners();
  }

  set accentIndex(int value) {
    _accentIndex = value;
    notifyListeners();
  }

  set taskFilter(String value) {
    _taskFilter = value;
    notifyListeners();
  }

  void toggleCopilotPanel() {
    _copilotPanelOpen = !_copilotPanelOpen;
    notifyListeners();
  }

  void addCart() {
    _cartCount++;
    notifyListeners();
  }

  void clearCart() {
    _cartCount = 0;
    notifyListeners();
  }

  void addTask() {
    _tasks.add(DemoTask('New task ${_tasks.length + 1}'));
    notifyListeners();
  }

  void toggleTask(DemoTask task) {
    task.done = !task.done;
    notifyListeners();
  }

  void setPrompt(String value) {
    promptController.text = value;
    notifyListeners();
  }

  Future<void> runCopilot() async {
    if (_running) return;

    _running = true;
    _copilotPanelOpen = true;
    _status = 'Running';
    _events.clear();
    notifyListeners();

    final prompt = promptController.text.trim();
    final result = await _copilotController.run(
      prompt.isEmpty ? 'Open settings and enable dark mode' : prompt,
    );

    _running = false;
    _status = describeResult(result);
    notifyListeners();
  }

  void resetDemo() {
    displayNameController.clear();
    emailController.clear();
    notesController.clear();
    searchController.clear();
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
    _notifications = true;
    _autoSave = true;
    _compactMode = false;
    _status = 'Demo data reset';
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    promptController.dispose();
    displayNameController.dispose();
    emailController.dispose();
    notesController.dispose();
    searchController.dispose();
    super.dispose();
  }
}
