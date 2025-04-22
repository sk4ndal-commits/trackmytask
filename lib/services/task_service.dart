import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:trackmytasks/models/task.dart';
import 'package:trackmytasks/models/time_entry.dart';
import 'package:trackmytasks/services/database_service.dart';

class TaskService extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  // State
  List<Task> _tasks = [];
  List<TimeEntry> _timeEntries = [];
  TimeEntry? _activeTimeEntry;
  Task? _activeTask;

  // Predefined categories
  final List<String> _predefinedCategories = [
    'Work',
    'Personal',
    'Study',
    'Meeting',
    'Development',
    'Design',
    'Research',
    'Planning',
    'Documentation',
    'Other'
  ];

  // Getters
  List<Task> get tasks => _tasks;

  List<TimeEntry> get timeEntries => _timeEntries;

  TimeEntry? get activeTimeEntry => _activeTimeEntry;

  Task? get activeTask => _activeTask;

  bool get isTracking => _activeTimeEntry != null;

  // Get predefined categories
  List<String> get predefinedCategories => _predefinedCategories;

  // Get all unique categories currently in use
  List<String> get allCategories {
    final Set<String> categories = {};

    // Add all predefined categories
    categories.addAll(_predefinedCategories);

    // Add categories from existing tasks
    for (final task in _tasks) {
      if (task.category != null && task.category!.isNotEmpty) {
        categories.add(task.category!);
      }
    }

    return categories.toList()..sort();
  }

  // Timer for UI updates
  Timer? _timer;

  // Constructor
  TaskService() {
    _init();
  }

  // Initialize the service
  Future<void> _init() async {
    await _loadTasks();
    await _loadActiveTimeEntry();
    await _loadTimeEntries(); // Load all time entries

    // Start a timer to update the UI every second when tracking
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_activeTimeEntry != null) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Load all tasks from the database
  Future<void> _loadTasks() async {
    _tasks = await _db.getTasks();
    notifyListeners();
  }

  // Load all time entries from the database
  Future<void> _loadTimeEntries() async {
    _timeEntries = await _db.getTimeEntries(); // Fetch from database
    notifyListeners();
  }

  // Load the active time entry (if any)
  Future<void> _loadActiveTimeEntry() async {
    _activeTimeEntry = await _db.getActiveTimeEntry();
    if (_activeTimeEntry != null && _activeTimeEntry!.task != null) {
      _activeTask = _activeTimeEntry!.task;
    } else if (_activeTimeEntry != null) {
      _activeTask = await _db.getTask(_activeTimeEntry!.taskId);
    }
    notifyListeners();
  }

  // Create a new task
  Future<Task> createTask(String name, {String? description, String? category}) async {
    final task = Task(
      name: name,
      description: description,
      category: category,
    );

    final id = await _db.insertTask(task);
    final newTask = task.copyWith(id: id);
    _tasks.add(newTask);
    notifyListeners();
    return newTask;
  }

  // Update an existing task
  Future<void> updateTask(Task task) async {
    await _db.updateTask(task);
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      notifyListeners();
    }
  }

  // Delete a task
  Future<void> deleteTask(int taskId) async {
    await _db.deleteTask(taskId);
    _tasks.removeWhere((task) => task.id == taskId);
    notifyListeners();
  }

  // Start tracking time for a task
  Future<void> startTracking(Task task, {String? workLocation}) async {
    // Stop any active tracking first
    if (_activeTimeEntry != null) {
      await stopTracking();
    }

    // Set the task as active
    final updatedTask = task.copyWith(isActive: true);
    await updateTask(updatedTask);

    // Create a new time entry
    final timeEntry = TimeEntry(
      taskId: task.id!,
      startTime: DateTime.now(),
      task: updatedTask,
      taskName: updatedTask.name, // Store the task name directly
      workLocation: workLocation, // Store the work location
    );

    final id = await _db.insertTimeEntry(timeEntry);
    _activeTimeEntry = timeEntry.copyWith(id: id);
    _timeEntries.add(_activeTimeEntry!); // Add the new entry to the list
    _activeTask = updatedTask;

    notifyListeners();
  }

  // Stop tracking time
  Future<void> stopTracking() async {
    if (_activeTimeEntry != null) {
      // Update the time entry with end time
      final stoppedEntry = _activeTimeEntry!.stop();
      await _db.updateTimeEntry(stoppedEntry);

      // Update the local list of time entries
      final index =
          _timeEntries.indexWhere((entry) => entry.id == stoppedEntry.id);
      if (index != -1) {
        _timeEntries[index] = stoppedEntry;
      }

      // Set the task as inactive
      if (_activeTask != null) {
        final updatedTask = _activeTask!.copyWith(isActive: false);
        await updateTask(updatedTask);
      }

      _activeTimeEntry = null;
      _activeTask = null;

      notifyListeners();
    }
  }

  // Get time entries for a specific day
  Future<List<TimeEntry>> getTimeEntriesForDay(DateTime date) async {
    return await _db.getTimeEntriesForDay(date);
  }

  // Helper method to process time entries and generate summary data
  Map<String, dynamic> _processSummaryData(List<TimeEntry> entries) {
    // Group entries by task
    final taskSummary = <int, Duration>{};
    for (final entry in entries) {
      final taskId = entry.taskId;
      final duration = entry.duration;

      if (taskSummary.containsKey(taskId)) {
        taskSummary[taskId] = taskSummary[taskId]! + duration;
      } else {
        taskSummary[taskId] = duration;
      }
    }

    // Group entries by work location
    final locationSummary = <String, Duration>{};
    for (final entry in entries) {
      final location = entry.workLocation ?? 'unknown';
      final duration = entry.duration;

      if (locationSummary.containsKey(location)) {
        locationSummary[location] = locationSummary[location]! + duration;
      } else {
        locationSummary[location] = duration;
      }
    }

    // Group entries by task and then by location
    final taskLocationSummary = <int, Map<String, Duration>>{};
    for (final entry in entries) {
      final taskId = entry.taskId;
      final location = entry.workLocation ?? 'unknown';
      final duration = entry.duration;

      // Initialize task map if it doesn't exist
      if (!taskLocationSummary.containsKey(taskId)) {
        taskLocationSummary[taskId] = {};
      }

      // Initialize or update location duration for this task
      if (taskLocationSummary[taskId]!.containsKey(location)) {
        taskLocationSummary[taskId]![location] = taskLocationSummary[taskId]![location]! + duration;
      } else {
        taskLocationSummary[taskId]![location] = duration;
      }
    }

    // Get task names and categories
    final taskNames = <int, String>{};
    final taskCategories = <int, String>{};

    // First try to get names and categories from existing tasks
    for (final task in _tasks) {
      if (task.id != null && taskSummary.containsKey(task.id)) {
        taskNames[task.id!] = task.name;
        if (task.category != null && task.category!.isNotEmpty) {
          taskCategories[task.id!] = task.category!;
        }
      }
    }

    // For tasks that don't exist anymore, use the stored task name from time entries
    for (final entry in entries) {
      if (!taskNames.containsKey(entry.taskId) && entry.taskName != null) {
        taskNames[entry.taskId] = entry.taskName!;
      }
    }

    // Group entries by category
    final categorySummary = <String, Duration>{};
    for (final entry in entries) {
      final taskId = entry.taskId;
      final duration = entry.duration;
      final category = taskCategories[taskId] ?? 'Uncategorized';

      if (categorySummary.containsKey(category)) {
        categorySummary[category] = categorySummary[category]! + duration;
      } else {
        categorySummary[category] = duration;
      }
    }

    // Calculate total duration
    final totalDuration = taskSummary.values.fold(
      Duration.zero,
      (total, duration) => total + duration,
    );

    return {
      'entries': entries,
      'taskSummary': taskSummary,
      'taskNames': taskNames,
      'taskCategories': taskCategories,
      'totalDuration': totalDuration,
      'locationSummary': locationSummary,
      'taskLocationSummary': taskLocationSummary,
      'categorySummary': categorySummary,
    };
  }

  // Get daily summary
  Future<Map<String, dynamic>> getDailySummary(DateTime date) async {
    final entries = await _db.getTimeEntriesForDay(date);
    return _processSummaryData(entries);
  }

  // Get weekly summary
  Future<Map<String, dynamic>> getWeeklySummary(DateTime date) async {
    final entries = await _db.getTimeEntriesForWeek(date);
    return _processSummaryData(entries);
  }

  // Get monthly summary
  Future<Map<String, dynamic>> getMonthlySummary(DateTime date) async {
    final entries = await _db.getTimeEntriesForMonth(date);
    return _processSummaryData(entries);
  }
}
