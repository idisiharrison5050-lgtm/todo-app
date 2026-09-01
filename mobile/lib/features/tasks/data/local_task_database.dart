import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../../auth/data/token_storage.dart';
import '../domain/task.dart';
import 'sync_metadata_store.dart';
import 'task_repository.dart';

class LocalTaskDatabase implements TaskRepository, SyncMetadataStore {
  static const _databaseName = 'todo.db';
  static const _databaseVersion = 4;
  static const _table = 'tasks';
  static const _deletedTable = 'pending_deletes';

  LocalTaskDatabase({TokenStorage? storage}) : _storage = storage ?? const TokenStorage();

  final TokenStorage _storage;
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
            account_key TEXT NOT NULL DEFAULT '',
            title TEXT NOT NULL,
            notes TEXT NOT NULL DEFAULT '',
            due_at TEXT,
            reminder_type TEXT NOT NULL,
            reminder_interval_minutes INTEGER,
            priority TEXT NOT NULL,
            is_completed INTEGER NOT NULL DEFAULT 0,
            payload TEXT
          )
        ''');
        await db.execute('CREATE INDEX idx_tasks_due_at ON $_table(due_at)');
        await db.execute('CREATE INDEX idx_tasks_account_key ON $_table(account_key)');
        await db.execute('''
          CREATE TABLE $_deletedTable (
            id TEXT PRIMARY KEY,
            account_key TEXT NOT NULL,
            deleted_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE $_table ADD COLUMN account_key TEXT NOT NULL DEFAULT ''");
          await db.execute('CREATE INDEX idx_tasks_account_key ON $_table(account_key)');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE $_table ADD COLUMN payload TEXT');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE $_deletedTable (
              id TEXT PRIMARY KEY,
              account_key TEXT NOT NULL,
              deleted_at TEXT NOT NULL
            )
          ''');
        }
      },
    );
    return _database!;
  }

  Future<String> _accountKey() async {
    final token = await _storage.read();
    if (token == null || token.isEmpty) return 'anonymous';
    return sha256.convert(utf8.encode(token)).toString();
  }

  @override
  Future<List<Task>> getTasks() async {
    final accountKey = await _accountKey();
    final rows = await (await _db).query(
      _table,
      where: 'account_key = ?',
      whereArgs: [accountKey],
      orderBy: 'due_at IS NULL, due_at ASC, id ASC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<void> saveTask(Task task) async {
    final accountKey = await _accountKey();
    final db = await _db;
    await db.delete(_deletedTable, where: 'id = ? AND account_key = ?', whereArgs: [task.id, accountKey]);
    await db.insert(
      _table,
      {..._toRow(task), 'account_key': accountKey},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteTask(String id) async {
    final accountKey = await _accountKey();
    final db = await _db;
    await db.delete(_table, where: 'id = ? AND account_key = ?', whereArgs: [id, accountKey]);
  }

  @override
  Future<List<String>> getPendingDeletes() async {
    final accountKey = await _accountKey();
    final rows = await (await _db).query(_deletedTable, columns: ['id'], where: 'account_key = ?', whereArgs: [accountKey], orderBy: 'deleted_at ASC');
    return rows.map((row) => row['id']! as String).toList(growable: false);
  }

  @override
  Future<void> addPendingDelete(String id) async {
    final accountKey = await _accountKey();
    await (await _db).insert(
      _deletedTable,
      {'id': id, 'account_key': accountKey, 'deleted_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> clearPendingDelete(String id) async {
    final accountKey = await _accountKey();
    await (await _db).delete(_deletedTable, where: 'id = ? AND account_key = ?', whereArgs: [id, accountKey]);
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
      'payload': jsonEncode(task.toJson()),
    };
  }

  Task _fromRow(Map<String, Object?> row) {
    final payload = row['payload'] as String?;
    if (payload != null && payload.isNotEmpty) {
      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map) return Task.fromJson(Map<String, dynamic>.from(decoded));
      } catch (_) {}
    }

    final reminderType = TaskReminderType.values.firstWhere((value) => value.name == row['reminder_type'], orElse: () => TaskReminderType.none);
    final priority = TaskPriority.values.firstWhere((value) => value.name == row['priority'], orElse: () => TaskPriority.normal);
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
