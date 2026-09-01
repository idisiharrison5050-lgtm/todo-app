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
  static const _databaseVersion = 6;
  static const _table = 'tasks';
  static const _deletedTable = 'pending_deletes';
  static const _operationsTable = 'pending_operations';
  LocalTaskDatabase({TokenStorage? storage}) : _storage = storage ?? const TokenStorage();
  final TokenStorage _storage;
  Database? _database;

  Future<Database> get _db async {
    if (_database != null) return _database!;
    final databasesPath = await getDatabasesPath();
    final databasePath = path.join(databasesPath, _databaseName);
    _database = await openDatabase(databasePath, version: _databaseVersion, onCreate: (db, version) async {
      await db.execute('CREATE TABLE $_table (id TEXT PRIMARY KEY, account_key TEXT NOT NULL DEFAULT \'\', title TEXT NOT NULL, notes TEXT NOT NULL DEFAULT \'\', due_at TEXT, reminder_type TEXT NOT NULL, reminder_interval_minutes INTEGER, priority TEXT NOT NULL, is_completed INTEGER NOT NULL DEFAULT 0, payload TEXT, updated_at TEXT)');
      await db.execute('CREATE INDEX idx_tasks_due_at ON $_table(due_at)');
      await db.execute('CREATE INDEX idx_tasks_account_key ON $_table(account_key)');
      await db.execute('CREATE TABLE $_deletedTable (id TEXT PRIMARY KEY, account_key TEXT NOT NULL, deleted_at TEXT NOT NULL)');
      await db.execute('CREATE TABLE $_operationsTable (id TEXT PRIMARY KEY, account_key TEXT NOT NULL, operation TEXT NOT NULL, updated_at TEXT NOT NULL)');
      await db.execute('CREATE INDEX idx_pending_operations_account ON $_operationsTable(account_key)');
    }, onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) { await db.execute("ALTER TABLE $_table ADD COLUMN account_key TEXT NOT NULL DEFAULT ''"); await db.execute('CREATE INDEX idx_tasks_account_key ON $_table(account_key)'); }
      if (oldVersion < 3) await db.execute('ALTER TABLE $_table ADD COLUMN payload TEXT');
      if (oldVersion < 4) await db.execute('CREATE TABLE $_deletedTable (id TEXT PRIMARY KEY, account_key TEXT NOT NULL, deleted_at TEXT NOT NULL)');
      if (oldVersion < 5) await db.execute('ALTER TABLE $_table ADD COLUMN updated_at TEXT');
      if (oldVersion < 6) { await db.execute('CREATE TABLE $_operationsTable (id TEXT PRIMARY KEY, account_key TEXT NOT NULL, operation TEXT NOT NULL, updated_at TEXT NOT NULL)'); await db.execute('CREATE INDEX idx_pending_operations_account ON $_operationsTable(account_key)'); }
    });
    return _database!;
  }
  Future<String> _accountKey() async { final token = await _storage.read(); if (token == null || token.isEmpty) return 'anonymous'; return sha256.convert(utf8.encode(token)).toString(); }
  @override Future<List<Task>> getTasks() async { final key = await _accountKey(); final rows = await (await _db).query(_table, where: 'account_key = ?', whereArgs: [key], orderBy: 'due_at IS NULL, due_at ASC, id ASC'); return rows.map(_fromRow).toList(growable: false); }
  @override Future<void> saveTask(Task task) async { final key = await _accountKey(); final db = await _db; await db.delete(_deletedTable, where: 'id = ? AND account_key = ?', whereArgs: [task.id, key]); await db.insert(_table, {..._toRow(task), 'account_key': key}, conflictAlgorithm: ConflictAlgorithm.replace); }
  @override Future<void> deleteTask(String id) async { final key = await _accountKey(); await (await _db).delete(_table, where: 'id = ? AND account_key = ?', whereArgs: [id, key]); }
  @override Future<List<PendingOperation>> getPendingOperations() async { final key = await _accountKey(); final rows = await (await _db).query(_operationsTable, where: 'account_key = ?', whereArgs: [key], orderBy: 'updated_at ASC, id ASC'); return rows.map((row) => PendingOperation(id: row['id']! as String, type: row['operation'] == 'delete' ? PendingOperationType.delete : PendingOperationType.upsert, updatedAt: DateTime.tryParse(row['updated_at']! as String) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true))).toList(growable: false); }
  @override Future<void> markPendingUpsert(String id, DateTime updatedAt) async { final key = await _accountKey(); await (await _db).insert(_operationsTable, {'id': id, 'account_key': key, 'operation': 'upsert', 'updated_at': updatedAt.toUtc().toIso8601String()}, conflictAlgorithm: ConflictAlgorithm.replace); await (await _db).delete(_deletedTable, where: 'id = ? AND account_key = ?', whereArgs: [id, key]); }
  @override Future<void> clearPendingOperation(String id) async { final key = await _accountKey(); await (await _db).delete(_operationsTable, where: 'id = ? AND account_key = ?', whereArgs: [id, key]); }
  @override Future<List<String>> getPendingDeletes() async { final key = await _accountKey(); final rows = await (await _db).query(_deletedTable, columns: ['id'], where: 'account_key = ?', whereArgs: [key], orderBy: 'deleted_at ASC'); return rows.map((row) => row['id']! as String).toList(growable: false); }
  @override Future<void> addPendingDelete(String id) async { final key = await _accountKey(); final db = await _db; await db.insert(_deletedTable, {'id': id, 'account_key': key, 'deleted_at': DateTime.now().toUtc().toIso8601String()}, conflictAlgorithm: ConflictAlgorithm.replace); await db.insert(_operationsTable, {'id': id, 'account_key': key, 'operation': 'delete', 'updated_at': DateTime.now().toUtc().toIso8601String()}, conflictAlgorithm: ConflictAlgorithm.replace); }
  @override Future<void> clearPendingDelete(String id) async { await clearPendingOperation(id); }
  @override Future<void> close() async { final database = _database; _database = null; await database?.close(); }
  Map<String, Object?> _toRow(Task task) => {'id': task.id, 'title': task.title, 'notes': task.notes, 'due_at': task.dueAt?.toIso8601String(), 'reminder_type': task.reminderType.name, 'reminder_interval_minutes': task.reminderInterval?.inMinutes, 'priority': task.priority.name, 'is_completed': task.isCompleted ? 1 : 0, 'payload': jsonEncode(task.toJson()), 'updated_at': task.updatedAt?.toIso8601String()};
  Task _fromRow(Map<String, Object?> row) { final payload = row['payload'] as String?; if (payload != null && payload.isNotEmpty) { try { final decoded = jsonDecode(payload); if (decoded is Map) return Task.fromJson(Map<String, dynamic>.from(decoded)); } catch (_) {} } final type = TaskReminderType.values.firstWhere((v) => v.name == row['reminder_type'], orElse: () => TaskReminderType.none); final priority = TaskPriority.values.firstWhere((v) => v.name == row['priority'], orElse: () => TaskPriority.normal); final interval = row['reminder_interval_minutes'] as int?; final due = row['due_at'] as String?; final updated = row['updated_at'] as String?; return Task(id: row['id']! as String, title: row['title']! as String, notes: row['notes'] as String? ?? '', dueAt: due == null ? null : DateTime.tryParse(due), reminderType: type, reminderInterval: interval == null ? null : Duration(minutes: interval), priority: priority, isCompleted: (row['is_completed'] as int? ?? 0) == 1, updatedAt: updated == null ? null : DateTime.tryParse(updated)); }
}
