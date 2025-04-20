import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trackmytasks/models/time_entry.dart';
import 'package:trackmytasks/services/task_service.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Summary'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export',
            onSelected: (value) async {
              final summaryData =
                  await Provider.of<TaskService>(context, listen: false)
                      .getDailySummary(_selectedDate);

              if (summaryData['taskSummary'].isEmpty && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No data to export')),
                );
                return;
              }

              if (context.mounted) {
                if (value == 'csv') {
                  await _showPathInputDialog(
                    context,
                    'Export Summary as CSV',
                    'csv',
                    (filePath) => _exportToCsv(summaryData, filePath),
                  );
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'csv',
                child: Text('Export as CSV'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Date selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    setState(() {
                      _selectedDate =
                          _selectedDate.subtract(const Duration(days: 1));
                    });
                  },
                ),
                Text(
                  DateFormat.yMMMMd().format(_selectedDate),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () {
                    final tomorrow =
                        DateTime.now().add(const Duration(days: 1));
                    if (_selectedDate.isBefore(tomorrow)) {
                      setState(() {
                        _selectedDate =
                            _selectedDate.add(const Duration(days: 1));
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          // Summary content
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: Provider.of<TaskService>(context, listen: false)
                  .getDailySummary(_selectedDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading summary: ${snapshot.error}',
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  );
                }

                final summaryData = snapshot.data!;
                final entries = summaryData['entries'] as List<TimeEntry>;
                final taskSummary =
                    summaryData['taskSummary'] as Map<int, Duration>;
                final taskNames = summaryData['taskNames'] as Map<int, String>;
                final totalDuration = summaryData['totalDuration'] as Duration;

                if (entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy,
                            size: 64,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text(
                          'No time tracked on this day',
                          style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total time card
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Time',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatDuration(totalDuration),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'Time by Task',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),

                      const SizedBox(height: 8),

                      // Combined list view for both summaries
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Task summary list with location breakdown
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: taskSummary.length,
                                itemBuilder: (context, index) {
                                  final taskId =
                                      taskSummary.keys.elementAt(index);
                                  final duration = taskSummary[taskId]!;
                                  // Find the first entry with this taskId to get the task name
                                  final entry = entries.firstWhere(
                                    (e) => e.taskId == taskId,
                                    orElse: () => TimeEntry(
                                        taskId: taskId,
                                        startTime: DateTime.now()),
                                  );
                                  final taskName = entry.taskName ??
                                      taskNames[taskId] ??
                                      'Unknown Task';

                                  // Get location breakdown for this task
                                  final taskLocationMap = 
                                      summaryData['taskLocationSummary'][taskId] as Map<String, Duration>;

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: Column(
                                      children: [
                                        // Main task row
                                        ListTile(
                                          leading: Icon(Icons.task_alt,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary),
                                          title: Text(taskName),
                                          trailing: Text(
                                            _formatDuration(duration),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),

                                        // Location breakdown
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 16.0, 
                                            right: 16.0, 
                                            bottom: 8.0
                                          ),
                                          child: Column(
                                            children: taskLocationMap.entries.map((locationEntry) {
                                              final location = locationEntry.key;
                                              final locationDuration = locationEntry.value;

                                              // Format location name for display
                                              String displayLocation;
                                              IconData locationIcon;

                                              if (location == 'home') {
                                                displayLocation = 'Home';
                                                locationIcon = Icons.home;
                                              } else if (location == 'office') {
                                                displayLocation = 'Office';
                                                locationIcon = Icons.business;
                                              } else {
                                                displayLocation = 'Unknown Location';
                                                locationIcon = Icons.question_mark;
                                              }

                                              return Padding(
                                                padding: const EdgeInsets.only(top: 4.0),
                                                child: Row(
                                                  children: [
                                                    Icon(locationIcon, 
                                                      size: 16, 
                                                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.7)
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(displayLocation),
                                                    const Spacer(),
                                                    Text(
                                                      _formatDuration(locationDuration),
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w500,
                                                        color: Theme.of(context).colorScheme.secondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 16),

                              Text(
                                'Detailed Time Entries',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),

                              const SizedBox(height: 8),

                              // Detailed time entries
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: entries.length,
                                itemBuilder: (context, index) {
                                  final entry = entries[index];
                                  final taskName = entry.task?.name ??
                                      entry.taskName ??
                                      taskNames[entry.taskId] ??
                                      'Unknown Task';

                                  // Get location icon
                                  IconData locationIcon;

                                  if (entry.workLocation == 'home') {
                                    locationIcon = Icons.home;
                                  } else if (entry.workLocation == 'office') {
                                    locationIcon = Icons.business;
                                  } else {
                                    locationIcon = Icons.location_on;
                                  }

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
                                              Icon(locationIcon, size: 16),
                                              const SizedBox(width: 4),
                                              Text(entry.workLocation?.capitalize() ?? 'Unknown location'),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: Text(
                                        entry.formattedDuration,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      isThreeLine: true,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
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

  String _formatTime(DateTime time) {
    return DateFormat.Hm().format(time);
  }

  /// Shows a dialog for the user to input a file path
  Future<void> _showPathInputDialog(BuildContext context, String title,
      String extension, Function(String) onSubmit) async {
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

  /// Export summary to CSV
  Future<void> _exportToCsv(
      Map<String, dynamic> summaryData, String filePath) async {
    try {
      // Extract data from summary
      final taskSummary = summaryData['taskSummary'] as Map<int, Duration>;
      final taskNames = summaryData['taskNames'] as Map<int, String>;
      final entries = summaryData['entries'] as List<TimeEntry>;
      final locationSummary = summaryData['locationSummary'] as Map<String, Duration>;

      // Prepare data for CSV
      final List<List<dynamic>> csvData = [
        ['Date', 'Task', 'Location', 'Duration (HH:MM:SS)', 'Time Homeoffice', 'Time Office'] // Header row
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
      csvData.add(['Task', 'Location', 'Duration (HH:MM:SS)', 'Time Homeoffice', 'Time Office', '']);

      final taskLocationSummary = summaryData['taskLocationSummary'] as Map<int, Map<String, Duration>>;

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
      csvData.add(['Location', 'Duration (HH:MM:SS)', '', 'Time Homeoffice', 'Time Office', '']);

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
