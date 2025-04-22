import 'dart:async';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trackmytasks/models/task.dart';
import 'package:trackmytasks/models/time_entry.dart';
import 'package:trackmytasks/models/user.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();

  static DatabaseService get instance => _instance;

  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'trackmytasks.db');
    return await openDatabase(
      path,
      version: 5, // Increment version to trigger migration for password support
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _upgradeDatabase(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Check if taskName column exists in time_entries table
      final result = await db.rawQuery("PRAGMA table_info(time_entries)");
      final columnNames =
          result.map((column) => column['name'] as String).toList();

      if (!columnNames.contains('taskName')) {
        // Add taskName column to time_entries table
        await db.execute('ALTER TABLE time_entries ADD COLUMN taskName TEXT');
      }
    }

    if (oldVersion < 3) {
      // Check if workLocation column exists in time_entries table
      final result = await db.rawQuery("PRAGMA table_info(time_entries)");
      final columnNames =
          result.map((column) => column['name'] as String).toList();

      if (!columnNames.contains('workLocation')) {
        // Add workLocation column to time_entries table
        await db.execute('ALTER TABLE time_entries ADD COLUMN workLocation TEXT');
      }
    }

    if (oldVersion < 4) {
      // Create users table
      await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE,
          profilePicture TEXT,
          createdAt TEXT NOT NULL
        )
      ''');

      // Add userId column to tasks table
      await db.execute('ALTER TABLE tasks ADD COLUMN userId INTEGER');

      // Add userId column to time_entries table
      await db.execute('ALTER TABLE time_entries ADD COLUMN userId INTEGER');
    }

    if (oldVersion < 5) {
      // Add password column to users table
      await db.execute('ALTER TABLE users ADD COLUMN password TEXT');
    }
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT,
        profilePicture TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create tasks table
    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        isActive INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        userId INTEGER,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE SET NULL
      )
    ''');

    // Create time_entries table
    await db.execute('''
      CREATE TABLE time_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        taskId INTEGER NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT,
        taskName TEXT,
        workLocation TEXT,
        userId INTEGER,
        FOREIGN KEY (taskId) REFERENCES tasks (id) ON DELETE CASCADE,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE SET NULL
      )
    ''');
  }

  // Task operations
  Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert('tasks', task.toMap());
  }

  Future<List<Task>> getTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      orderBy: 'createdAt DESC', // Order by creation date, newest first
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  Future<Task?> getTask(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Task.fromMap(maps.first);
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Time entry operations
  Future<int> insertTimeEntry(TimeEntry entry) async {
    final db = await database;
    return await db.insert('time_entries', entry.toMap());
  }

  Future<List<TimeEntry>> getTimeEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('time_entries');
    return List.generate(maps.length, (i) => TimeEntry.fromMap(maps[i]));
  }

  Future<TimeEntry?> getTimeEntry(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'time_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return TimeEntry.fromMap(maps.first);
  }

  Future<int> updateTimeEntry(TimeEntry entry) async {
    final db = await database;
    return await db.update(
      'time_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteTimeEntry(int id) async {
    final db = await database;
    return await db.delete(
      'time_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get active time entry (if any)
  Future<TimeEntry?> getActiveTimeEntry() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'time_entries',
      where: 'endTime IS NULL',
    );
    if (maps.isEmpty) return null;

    // Get the associated task
    final taskId = maps.first['taskId'];
    final task = await getTask(taskId);

    return TimeEntry.fromMap(maps.first, task: task);
  }

  // Get active time entry for a specific user (if any)
  Future<TimeEntry?> getActiveTimeEntryForUser(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'time_entries',
      where: 'endTime IS NULL AND userId = ?',
      whereArgs: [userId],
    );
    if (maps.isEmpty) return null;

    // Get the associated task
    final taskId = maps.first['taskId'];
    final task = await getTask(taskId);

    return TimeEntry.fromMap(maps.first, task: task);
  }

  // Get time entries for a specific day
  Future<List<TimeEntry>> getTimeEntriesForDay(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'time_entries',
      where: 'startTime >= ? AND startTime < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );

    // Get all tasks to associate with time entries
    final tasks = await getTasks();
    final taskMap = {for (var task in tasks) task.id: task};

    return List.generate(maps.length, (i) {
      final entry = TimeEntry.fromMap(maps[i]);
      return entry.copyWith(task: taskMap[entry.taskId]);
    });
  }

  // Get time entries with associated tasks
  Future<List<TimeEntry>> getTimeEntriesWithTasks() async {
    final entries = await getTimeEntries();
    final tasks = await getTasks();
    final taskMap = {for (var task in tasks) task.id: task};

    return entries
        .map((entry) => entry.copyWith(task: taskMap[entry.taskId]))
        .toList();
  }

  // User operations
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<List<User>> getUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      orderBy: 'name ASC', // Order by name alphabetically
    );
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  Future<User?> getUser(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get tasks for a specific user
  Future<List<Task>> getTasksForUser(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  // Get time entries for a specific user
  Future<List<TimeEntry>> getTimeEntriesForUser(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'time_entries',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    // Get all tasks to associate with time entries
    final tasks = await getTasks();
    final taskMap = {for (var task in tasks) task.id: task};

    return List.generate(maps.length, (i) {
      final entry = TimeEntry.fromMap(maps[i]);
      return entry.copyWith(task: taskMap[entry.taskId]);
    });
  }

  // Get time entries for a specific day and user
  Future<List<TimeEntry>> getTimeEntriesForDayAndUser(DateTime date, int userId) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'time_entries',
      where: 'startTime >= ? AND startTime < ? AND userId = ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String(), userId],
    );

    // Get all tasks to associate with time entries
    final tasks = await getTasks();
    final taskMap = {for (var task in tasks) task.id: task};

    return List.generate(maps.length, (i) {
      final entry = TimeEntry.fromMap(maps[i]);
      return entry.copyWith(task: taskMap[entry.taskId]);
    });
  }
}
