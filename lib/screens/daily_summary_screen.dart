import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trackmytasks/models/time_entry.dart';
import 'package:trackmytasks/services/task_service.dart';
import 'package:trackmytasks/widgets/theme_toggle_button.dart';

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class DailySummaryScreen extends StatefulWidget {
  const DailySummaryScreen({super.key});

  @override
  State<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends State<DailySummaryScreen> {
  DateTime _selectedDate = DateTime.now();
  String _reportType = 'daily'; // 'daily', 'weekly', or 'monthly'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: Column(
        children: [
          buildDateSelector(context),
          Expanded(child: buildSummaryContent(context)),
        ],
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    String title;
    switch (_reportType) {
      case 'weekly':
        title = 'Weekly Summary';
        break;
      case 'monthly':
        title = 'Monthly Summary';
        break;
      case 'daily':
      default:
        title = 'Daily Summary';
    }

    return AppBar(
      title: Text(title),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: [
        // Report type selector
        PopupMenuButton<String>(
          icon: const Icon(Icons.view_agenda),
          tooltip: 'Report Type',
          onSelected: (value) {
            setState(() {
              _reportType = value;
            });
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'daily',
              child: Text('Daily Report'),
            ),
            const PopupMenuItem<String>(
              value: 'weekly',
              child: Text('Weekly Report'),
            ),
            const PopupMenuItem<String>(
              value: 'monthly',
              child: Text('Monthly Report'),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () => _selectDate(context),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.file_download),
          tooltip: 'Export',
          onSelected: (value) => handleExport(context, value),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'csv',
              child: Text('Export as CSV'),
            ),
          ],
        ),
        const ThemeToggleButton(),
      ],
    );
  }

  Padding buildDateSelector(BuildContext context) {
    String dateText;
    Duration backwardDuration;
    Duration forwardDuration;

    switch (_reportType) {
      case 'weekly':
        // Find the start of the week (Monday)
        final startOfWeek = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day - _selectedDate.weekday + 1,
        );
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        dateText =
            '${DateFormat.MMMd().format(startOfWeek)} - ${DateFormat.MMMd().format(endOfWeek)}, ${DateFormat.y().format(_selectedDate)}';
        backwardDuration = const Duration(days: 7);
        forwardDuration = const Duration(days: 7);
        break;
      case 'monthly':
        final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
        final endOfMonth = (_selectedDate.month < 12)
            ? DateTime(_selectedDate.year, _selectedDate.month + 1, 0)
            : DateTime(_selectedDate.year + 1, 1, 0);
        dateText = DateFormat.yMMMM().format(_selectedDate);
        // For months, we need to handle variable durations
        backwardDuration = Duration(days: startOfMonth.day);
        forwardDuration = Duration(days: 1);
        break;
      case 'daily':
      default:
        dateText = DateFormat.yMMMMd().format(_selectedDate);
        backwardDuration = const Duration(days: 1);
        forwardDuration = const Duration(days: 1);
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              setState(() {
                if (_reportType == 'monthly') {
                  // For months, go to previous month
                  if (_selectedDate.month == 1) {
                    _selectedDate = DateTime(_selectedDate.year - 1, 12, 1);
                  } else {
                    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
                  }
                } else {
                  _selectedDate = _selectedDate.subtract(backwardDuration);
                }
              });
            },
          ),
          Text(
            dateText,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () {
              final now = DateTime.now();
              bool canGoForward = true;

              if (_reportType == 'monthly') {
                // For months, check if we're already in the current month
                canGoForward = _selectedDate.year < now.year ||
                    (_selectedDate.year == now.year && _selectedDate.month < now.month);

                if (canGoForward) {
                  setState(() {
                    if (_selectedDate.month == 12) {
                      _selectedDate = DateTime(_selectedDate.year + 1, 1, 1);
                    } else {
                      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
                    }
                  });
                }
              } else if (_reportType == 'weekly') {
                // For weeks, check if the end of the next week is in the future
                final startOfNextWeek = DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day - _selectedDate.weekday + 8,
                );
                canGoForward = startOfNextWeek.isBefore(now);

                if (canGoForward) {
                  setState(() {
                    _selectedDate = _selectedDate.add(forwardDuration);
                  });
                }
              } else {
                // For days, check if the next day is in the future
                canGoForward = _selectedDate.add(forwardDuration).isBefore(now);

                if (canGoForward) {
                  setState(() {
                    _selectedDate = _selectedDate.add(forwardDuration);
                  });
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget buildSummaryContent(BuildContext context) {
    Future<Map<String, dynamic>> getSummaryData() {
      final taskService = Provider.of<TaskService>(context, listen: false);
      switch (_reportType) {
        case 'weekly':
          return taskService.getWeeklySummary(_selectedDate);
        case 'monthly':
          return taskService.getMonthlySummary(_selectedDate);
        case 'daily':
        default:
          return taskService.getDailySummary(_selectedDate);
      }
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: getSummaryData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return buildErrorContent(context, snapshot.error.toString());
        }

        if (snapshot.hasData) {
          return buildSummaryDetails(context, snapshot.data!);
        }

        return buildEmptyContent(context);
      },
    );
  }

  Widget buildErrorContent(BuildContext context, String errorMessage) {
    return Center(
      child: Text(
        'Error loading summary: $errorMessage',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  Widget buildEmptyContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy,
              size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'No time tracked on this day',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSummaryDetails(
      BuildContext context, Map<String, dynamic> summaryData) {
    final entries = summaryData['entries'] as List<TimeEntry>;
    final taskSummary = summaryData['taskSummary'] as Map<int, Duration>;
    final taskNames = summaryData['taskNames'] as Map<int, String>;
    final totalDuration = summaryData['totalDuration'] as Duration;
    final categorySummary = summaryData['categorySummary'] as Map<String, Duration>;
    final taskCategories = summaryData['taskCategories'] as Map<int, String>? ?? {};

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTotalTimeCard(context, totalDuration),
          const SizedBox(height: 16),
          Text('Time by Category', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          buildCategorySummaryList(context, categorySummary),
          const SizedBox(height: 16),
          Text('Time by Task', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildTaskSummaryList(context, entries, taskSummary, taskNames,
                      summaryData['taskLocationSummary'], taskCategories),
                  const SizedBox(height: 16),
                  Text('Detailed Time Entries',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  buildDetailedEntriesList(context, entries, taskNames),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Card buildTotalTimeCard(BuildContext context, Duration totalDuration) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Time', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              _formatDuration(totalDuration),
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCategorySummaryList(
      BuildContext context, Map<String, Duration> categorySummary) {
    // Sort categories by duration (descending)
    final sortedCategories = categorySummary.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final entry = sortedCategories[index];
        final category = entry.key;
        final duration = entry.value;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              Icons.category,
              color: Theme.of(context).colorScheme.secondary,
            ),
            title: Text(category),
            trailing: Text(
              _formatDuration(duration),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildTaskSummaryList(
      BuildContext context,
      List<TimeEntry> entries,
      Map<int, Duration> taskSummary,
      Map<int, String> taskNames,
      Map<int, Map<String, Duration>> taskLocationSummary,
      [Map<int, String>? taskCategories]) {
    // Sort tasks by duration (descending)
    final sortedTasks = taskSummary.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedTasks.length,
      itemBuilder: (context, index) {
        final entry = sortedTasks[index];
        final taskId = entry.key;
        final duration = entry.value;
        final taskName = taskNames[taskId] ?? 'Unknown Task';
        final category = taskCategories?[taskId];
        final locationMap = taskLocationSummary[taskId] ?? {};

        return buildTaskCard(context, taskName, duration, locationMap, category);
      },
    );
  }

  Card buildTaskCard(BuildContext context, String taskName, Duration duration,
      Map<String, Duration> locationMap, [String? category]) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.task_alt,
                color: Theme.of(context).colorScheme.secondary),
            title: Row(
              children: [
                Expanded(child: Text(taskName)),
                if (category != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: Text(
              _formatDuration(duration),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: locationMap.entries.map((entry) {
                return buildLocationRow(context, entry.key, entry.value);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Row buildLocationRow(
      BuildContext context, String location, Duration duration) {
    final locationIcons = {
      'home': Icons.home,
      'office': Icons.business,
      'unknown': Icons.question_mark
    };

    final icon = locationIcons[location] ?? locationIcons['unknown']!;
    return Row(
      children: [
        Icon(icon,
            size: 16,
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.7)),
        const SizedBox(width: 8),
        Text(location.capitalize()),
        const Spacer(),
        Text(
          _formatDuration(duration),
          style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.secondary),
        ),
      ],
    );
  }

  Widget buildDetailedEntriesList(BuildContext context, List<TimeEntry> entries,
      Map<int, String> taskNames) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final taskName = entry.task?.name ??
            entry.taskName ??
            taskNames[entry.taskId] ??
            'Unknown Task';
        return buildDetailedEntryCard(entry, taskName);
      },
    );
  }

  Card buildDetailedEntryCard(TimeEntry entry, String taskName) {
    final locationIcons = {
      'home': Icons.home,
      'office': Icons.business,
      'unknown': Icons.location_on
    };

    final icon =
        locationIcons[entry.workLocation ?? 'unknown'] ?? Icons.location_on;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(taskName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_formatTime(entry.startTime)} - ${entry.endTime != null ? _formatTime(entry.endTime!) : 'In progress'}',
            ),
            Row(
              children: [
                Icon(icon, size: 16),
                const SizedBox(width: 4),
                Text(entry.workLocation?.capitalize() ?? 'Unknown location'),
              ],
            ),
          ],
        ),
        trailing: Text(
          entry.formattedDuration,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        isThreeLine: true,
      ),
    );
  }

  Future<void> handleExport(BuildContext context, String value) async {
    // Get the appropriate summary data based on report type
    final taskService = Provider.of<TaskService>(context, listen: false);
    Map<String, dynamic> summaryData;

    switch (_reportType) {
      case 'weekly':
        summaryData = await taskService.getWeeklySummary(_selectedDate);
        break;
      case 'monthly':
        summaryData = await taskService.getMonthlySummary(_selectedDate);
        break;
      case 'daily':
      default:
        summaryData = await taskService.getDailySummary(_selectedDate);
    }

    if (summaryData['taskSummary'].isEmpty && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    if (value == 'csv' && context.mounted) {
      String title;
      switch (_reportType) {
        case 'weekly':
          final startOfWeek = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day - _selectedDate.weekday + 1,
          );
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          title = 'Export Weekly Summary (${DateFormat.MMMd().format(startOfWeek)} - ${DateFormat.MMMd().format(endOfWeek)})';
          break;
        case 'monthly':
          title = 'Export Monthly Summary (${DateFormat.yMMMM().format(_selectedDate)})';
          break;
        case 'daily':
        default:
          title = 'Export Daily Summary (${DateFormat.yMMMd().format(_selectedDate)})';
      }

      await _showPathInputDialog(context, title, 'csv',
          (filePath) => _exportToCsv(summaryData, filePath));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _formatTime(DateTime time) => DateFormat.Hm().format(time);

  Future<void> _showPathInputDialog(BuildContext context, String title,
      String extension, Function(String) onSubmit) async {
    // Path input logic remains unchanged
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Enter file path',
            hintText: '/path/to/your/file.$extension',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final filePath = controller.text.trim();
              if (filePath.isNotEmpty && filePath.endsWith('.$extension')) {
                Navigator.pop(dialogContext);
                onSubmit(filePath);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please provide a valid file path')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToCsv(
    Map<String, dynamic> summaryData,
    String filePath,
  ) async {
    // Export logic remains unchanged
    try {
      // Extract data from summary
      final taskSummary = summaryData['taskSummary'] as Map<int, Duration>;
      final taskNames = summaryData['taskNames'] as Map<int, String>;
      final entries = summaryData['entries'] as List<TimeEntry>;
      final locationSummary =
          summaryData['locationSummary'] as Map<String, Duration>;

      // Prepare data for CSV
      final List<List<dynamic>> csvData = [
        [
          'Date',
          'Task',
          'Location',
          'Duration (HH:MM:SS)',
          'Time Homeoffice',
          'Time Office'
        ] // Header row
      ];

      // Add each task with its date, name, location, and duration
      for (final entry in entries) {
        final taskDate = DateFormat.yMMMd().format(entry.startTime);
        final taskName = entry.task?.name ??
            entry.taskName ??
            taskNames[entry.taskId] ??
            'Unknown Task';
        final location = entry.workLocation?.capitalize() ?? 'Unknown';

        // Calculate time for home and office
        String homeTime = '';
        String officeTime = '';

        if (entry.workLocation == 'home') {
          homeTime = entry.formattedDuration;
        } else if (entry.workLocation == 'office') {
          officeTime = entry.formattedDuration;
        }

        csvData.add([
          taskDate,
          taskName,
          location,
          entry.formattedDuration,
          homeTime,
          officeTime
        ]);
      }

      // Add a blank row
      csvData.add(['', '', '', '', '', '']);

      // Add summary by task with location breakdown
      csvData.add(['Summary by Task', '', '', '', '', '']);
      csvData.add([
        'Task',
        'Location',
        'Duration (HH:MM:SS)',
        'Time Homeoffice',
        'Time Office',
        ''
      ]);

      final taskLocationSummary =
          summaryData['taskLocationSummary'] as Map<int, Map<String, Duration>>;

      taskSummary.forEach((taskId, totalDuration) {
        final taskName = taskNames[taskId] ?? 'Unknown Task';
        // Get home and office durations for this task
        final locationMap = taskLocationSummary[taskId]!;
        final homeDuration = locationMap['home'] ?? Duration.zero;
        final officeDuration = locationMap['office'] ?? Duration.zero;

        // Add the task with its total duration
        csvData.add([
          taskName,
          'Total',
          _formatDuration(totalDuration),
          _formatDuration(homeDuration),
          _formatDuration(officeDuration),
          ''
        ]);

        // Add location breakdown for this task
        locationMap.forEach((location, duration) {
          final displayLocation = location.capitalize();
          String homeTime = '';
          String officeTime = '';

          if (location == 'home') {
            homeTime = _formatDuration(duration);
          } else if (location == 'office') {
            officeTime = _formatDuration(duration);
          }

          csvData.add([
            '',
            displayLocation,
            _formatDuration(duration),
            homeTime,
            officeTime,
            ''
          ]);
        });

        // Add a blank row after each task
        csvData.add(['', '', '', '', '', '']);
      });

      // Add summary by location
      csvData.add(['Summary by Location', '', '', '', '', '']);
      csvData.add([
        'Location',
        'Duration (HH:MM:SS)',
        '',
        'Time Homeoffice',
        'Time Office',
        ''
      ]);

      locationSummary.forEach((location, duration) {
        final displayLocation = location.capitalize();
        String homeTime = '';
        String officeTime = '';

        if (location == 'home') {
          homeTime = _formatDuration(duration);
        } else if (location == 'office') {
          officeTime = _formatDuration(duration);
        }

        csvData.add([
          displayLocation,
          _formatDuration(duration),
          '',
          homeTime,
          officeTime,
          ''
        ]);
      });

      // Save CSV file
      final file = File(filePath);
      await file.writeAsString(const ListToCsvConverter().convert(csvData));

      // Notify user of success
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to $filePath')),
        );
      }
    } catch (e) {
      // Notify user of failure
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export CSV: $e')),
        );
      }
    }
  }
}
