import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackmytasks/models/task.dart';
import 'package:trackmytasks/models/time_entry.dart';
import 'package:trackmytasks/services/task_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track My Tasks'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                          _buildActiveTaskInfo(context, activeTask, activeTimeEntry!)
                        else
                          const Text('No active task. Start tracking to begin.'),
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

                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/tasks');
                  },
                  icon: const Icon(Icons.list),
                  label: const Text('Manage Tasks'),
                ),

                const SizedBox(height: 8),

                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/summary');
                  },
                  icon: const Icon(Icons.summarize),
                  label: const Text('View Daily Summary'),
                ),

                const Spacer(),

                // App info
                Center(
                  child: Text(
                    'Track My Tasks - Your Desktop Time Tracking Assistant',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
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

  Widget _buildActiveTaskInfo(BuildContext context, Task task, TimeEntry timeEntry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.play_circle, color: Theme.of(context).colorScheme.primary),
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
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
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

  Widget _buildStartTrackingButton(BuildContext context, TaskService taskService) {
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
      icon: const Icon(Icons.play_arrow),
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
                  subtitle: task.description != null ? Text(task.description!) : null,
                  onTap: () {
                    Navigator.pop(context);
                    Provider.of<TaskService>(context, listen: false).startTracking(task);
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
}
