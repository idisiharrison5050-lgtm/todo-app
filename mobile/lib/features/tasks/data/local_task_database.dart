import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../domain/task.dart';
import 'task_repository.dart';

class LocalTaskDatabase implements TaskRepository {
  static const _databaseName = 'todo.db';
  static const _databaseVersion = 1;
  static const _table = 'tasks';

  Database? _database;

  Future<Database> get _db async {
    if (_database != null) return _database!;

    final databasesPath = await getDatabasesPath();
    final databasePath = path.join(databasesPath, _databaseName);
    _database = await openDatabase(
      databasePath,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            notes TEXT NOT NULL DEFAULT '',
            due_at TEXT,
            reminder_type TEXT NOT NULL,
            reminder_interval_minutes INTEGER,
            priority TEXT NOT NULL,
            is_completed INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_tasks_due_at ON $_table(due_at)',
        );
      },
    );
    return _database!;
  }

  @override
  Future<List<Task>> getTasks() async {
    final rows = await (await _db).query(
      _table,
      orderBy: 'due_at IS NULL, due_at ASC, id ASC',
    );

    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<void> saveTask(Task task) async {
    await (await _db).insert(
      _table,
      _toRow(task),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteTask(String id) async {
    await (await _db).delete(
      _table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> close() async {
    final database = _database;
    _database = null;
    await database?.close();
  }

  Map<String, Object?> _toRow(Task task) {
    return {
      'id': task.id,
      'title': task.title,
      'notes': task.notes,
      'due_at': task.dueAt?.toIso8601String(),
      'reminder_type': task.reminderType.name,
      'reminder_interval_minutes': task.reminderInterval?.inMinutes,
      'priority': task.priority.name,
      'is_completed': task.isCompleted ? 1 : 0,
    };
  }

  Task _fromRow(Map<String, Object?> row) {
    final reminderType = TaskReminderType.values.firstWhere(
      (value) => value.name == row['reminder_type'],
      orElse: () => TaskReminderType.none,
    );
    final priority = TaskPriority.values.firstWhere(
      (value) => value.name == row['priority'],
      orElse: () => TaskPriority.normal,
    );
    final interval = row['reminder_interval_minutes'] as int?;
    final dueAtText = row['due_at'] as String?;

    return Task(
      id: row['id']! as String,
      title: row['title']! as String,
      notes: row['notes'] as String? ?? '',
      dueAt: dueAtText == null ? null : DateTime.tryParse(dueAtText),
      reminderType: reminderType,
      reminderInterval: interval == null ? null : Duration(minutes: interval),
      priority: priority,
      isCompleted: (row['is_completed'] as int? ?? 0) == 1,
    );
  }
}
