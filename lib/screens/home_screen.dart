import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackmytasks/models/task.dart';
import 'package:trackmytasks/models/time_entry.dart';
import 'package:trackmytasks/services/task_service.dart';
import 'package:trackmytasks/widgets/theme_toggle_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track My Tasks'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      body: Consumer<TaskService>(
        builder: (context, taskService, child) {
          final isTracking = taskService.isTracking;
          final activeTask = taskService.activeTask;
          final activeTimeEntry = taskService.activeTimeEntry;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        if (isTracking && activeTask != null)
                          _buildActiveTaskInfo(
                              context, activeTask, activeTimeEntry!)
                        else
                          const Text(
                              'No active task. Start tracking to begin.'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Quick actions
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),

                if (isTracking)
                  ElevatedButton.icon(
                    onPressed: () => taskService.stopTracking(),
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Tracking'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                  )
                else
                  _buildStartTrackingButton(context, taskService),

                const SizedBox(height: 16),

                // Recent Tasks (scrollable)
                if (!isTracking && taskService.tasks.isNotEmpty)
                  Expanded(
                    child: _buildScrollableRecentTasks(context, taskService),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildActiveTaskInfo(
      BuildContext context, Task task, TimeEntry timeEntry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.play_circle,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Currently tracking: ${task.name}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        if (task.description != null && task.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(task.description!),
          ),
        const SizedBox(height: 8),
        Text(
          'Started at: ${_formatTime(timeEntry.startTime)}',
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          'Duration: ${timeEntry.formattedDuration}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildStartTrackingButton(
      BuildContext context, TaskService taskService) {
    final tasks = taskService.tasks;

    if (tasks.isEmpty) {
      return ElevatedButton.icon(
        onPressed: () => _showAddTaskDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Create a Task to Start Tracking'),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _showTaskSelectionDialog(context, tasks),
      icon: Icon(
        Icons.play_arrow,
        // Ensure the arrow has a contrasting color to the background
        color: Theme.of(context).colorScheme.onPrimary,
      ),
      label: const Text('Start Tracking'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  void _showTaskSelectionDialog(BuildContext context, List<Task> tasks) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select a Task'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return ListTile(
                  title: Text(task.name),
                  subtitle:
                      task.description != null ? Text(task.description!) : null,
                  onTap: () {
                    Navigator.pop(context);
                    _showWorkLocationDialog(context, task);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showWorkLocationDialog(BuildContext context, Task task) {
    String? selectedLocation;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Work Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Where are you working from?'),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Home'),
                leading: Radio<String>(
                  value: 'home',
                  groupValue: selectedLocation,
                  onChanged: (value) {
                    selectedLocation = value;
                    Navigator.pop(context);
                    Provider.of<TaskService>(context, listen: false)
                        .startTracking(task, workLocation: 'home');
                  },
                ),
              ),
              ListTile(
                title: const Text('Office'),
                leading: Radio<String>(
                  value: 'office',
                  groupValue: selectedLocation,
                  onChanged: (value) {
                    selectedLocation = value;
                    Navigator.pop(context);
                    Provider.of<TaskService>(context, listen: false)
                        .startTracking(task, workLocation: 'office');
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Task Name',
                  hintText: 'Enter task name',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Enter task description',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  Provider.of<TaskService>(context, listen: false).createTask(
                    nameController.text.trim(),
                    description: descriptionController.text.trim().isNotEmpty
                        ? descriptionController.text.trim()
                        : null,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildScrollableRecentTasks(
      BuildContext context, TaskService taskService) {
    // Extract all time entries and tasks
    final tasks = taskService.tasks;
    final timeEntries =
        taskService.timeEntries; // Assuming TaskService provides this

    // Map tasks to their most recent tracking start time
    final Map<int, DateTime> taskIdToLastStartTime = {};

    for (var entry in timeEntries) {
      final taskId = entry.taskId;
      if (!taskIdToLastStartTime.containsKey(taskId) ||
          entry.startTime.isAfter(taskIdToLastStartTime[taskId]!)) {
        taskIdToLastStartTime[taskId] = entry.startTime;
      }
    }

    // Extract tasks with their most recent start time
    final recentTasks = tasks
        .where((task) => taskIdToLastStartTime.containsKey(task.id))
        .toList();

    // Sort tasks by their most recent start time (descending)
    recentTasks.sort((a, b) =>
        taskIdToLastStartTime[b.id]!.compareTo(taskIdToLastStartTime[a.id]!));

    // Take the top 3 recent tasks
    final topRecentTasks = recentTasks.take(5).toList();

    // Build the UI
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Tasks',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: topRecentTasks.length,
            itemBuilder: (context, index) {
              final task = topRecentTasks[index];
              return _buildRecentTaskItem(context, task, taskService);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTaskItem(
      BuildContext context, Task task, TaskService taskService) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(task.name),
        subtitle: task.description != null && task.description!.isNotEmpty
            ? Text(
                task.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: IconButton(
          icon: Icon(
            Icons.play_arrow,
            // Ensure the arrow has a contrasting color
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => _showWorkLocationDialog(context, task),
          tooltip: 'Start tracking',
        ),
        onTap: () => _showWorkLocationDialog(context, task),
      ),
    );
  }
}
