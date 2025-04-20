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
    return AppBar(
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
          onSelected: (value) => handleExport(context, value),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'csv',
              child: Text('Export as CSV'),
            ),
          ],
        ),
      ],
    );
  }

  Padding buildDateSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
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
              if (_selectedDate.isBefore(DateTime.now())) {
                setState(() {
                  _selectedDate = _selectedDate.add(const Duration(days: 1));
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget buildSummaryContent(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: Provider.of<TaskService>(context, listen: false)
          .getDailySummary(_selectedDate),
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTotalTimeCard(context, totalDuration),
          const SizedBox(height: 16),
          Text('Time by Task', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildTaskSummaryList(context, entries, taskSummary, taskNames,
                      summaryData['taskLocationSummary']),
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

  Widget buildTaskSummaryList(
      BuildContext context,
      List<TimeEntry> entries,
      Map<int, Duration> taskSummary,
      Map<int, String> taskNames,
      Map<int, Map<String, Duration>> taskLocationSummary) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: taskSummary.length,
      itemBuilder: (context, index) {
        final taskId = taskSummary.keys.elementAt(index);
        final duration = taskSummary[taskId]!;
        final taskName = taskNames[taskId] ?? 'Unknown Task';
        final locationMap = taskLocationSummary[taskId] ?? {};

        return buildTaskCard(context, taskName, duration, locationMap);
      },
    );
  }

  Card buildTaskCard(BuildContext context, String taskName, Duration duration,
      Map<String, Duration> locationMap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.task_alt,
                color: Theme.of(context).colorScheme.secondary),
            title: Text(taskName),
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
    final summaryData = await Provider.of<TaskService>(context, listen: false)
        .getDailySummary(_selectedDate);

    if (summaryData['taskSummary'].isEmpty && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    if (value == 'csv') {
      await _showPathInputDialog(context, 'Export Summary as CSV', 'csv',
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
  }

  Future<void> _exportToCsv(
    Map<String, dynamic> summaryData,
    String filePath,
  ) async {
    // Export logic remains unchanged
  }
}
