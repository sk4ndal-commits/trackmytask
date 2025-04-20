import 'package:trackmytasks/models/task.dart';

class TimeEntry {
  final int? id;
  final int taskId;
  final DateTime startTime;
  final DateTime? endTime;
  final Task? task; // Optional reference to the associated task
  final String? taskName; // Store the task name directly

  TimeEntry({
    this.id,
    required this.taskId,
    required this.startTime,
    this.endTime,
    this.task,
    this.taskName,
  });

  // Calculate the duration of this time entry
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  // Format the duration as a string (HH:MM:SS)
  String get formattedDuration {
    final dur = duration;
    final hours = dur.inHours.toString().padLeft(2, '0');
    final minutes = (dur.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (dur.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  // Check if this time entry is currently active (no end time)
  bool get isActive => endTime == null;

  // Create a TimeEntry from a map (for database operations)
  factory TimeEntry.fromMap(Map<String, dynamic> map, {Task? task}) {
    return TimeEntry(
      id: map['id'],
      taskId: map['taskId'],
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      task: task,
      taskName: map['taskName'],
    );
  }

  // Convert a TimeEntry to a map (for database operations)
  Map<String, dynamic> toMap() {
    final map = {
      'id': id,
      'taskId': taskId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };

    // Only include taskName if it's not null and the column exists in the database
    if (taskName != null) {
      map['taskName'] = taskName;
    }

    return map;
  }

  // Create a copy of this TimeEntry with the given fields replaced with the new values
  TimeEntry copyWith({
    int? id,
    int? taskId,
    DateTime? startTime,
    DateTime? endTime,
    Task? task,
    String? taskName,
  }) {
    return TimeEntry(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      task: task ?? this.task,
      taskName: taskName ?? this.taskName,
    );
  }

  // Create a new TimeEntry with the end time set to now
  TimeEntry stop() {
    return copyWith(endTime: DateTime.now());
  }
}
