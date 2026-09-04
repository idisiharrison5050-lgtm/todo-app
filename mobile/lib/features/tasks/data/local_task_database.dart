import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../auth/data/token_storage.dart';
import '../domain/task.dart';
import 'sync_metadata_store.dart';
import 'task_repository.dart';

class LocalTaskDatabase implements TaskRepository, SyncMetadataStore {
  LocalTaskDatabase({String? accountKey, TokenStorage? storage})
      : _accountKeyValue = accountKey,
        _storage = storage ?? const TokenStorage();

  final String? _accountKeyValue;
  final TokenStorage _storage;
  Database? _db;

  static const String _databaseName = 'todo_mobile.db';
  static const String _tasksTable = 'tasks';
  static const String _operationsTable = 'pending_operations';
  static const String _deletedTable = 'pending_deletes';

  Future<String?> _accountKey() async {
    final explicitKey = _accountKeyValue;
    if (explicitKey != null && explicitKey.isNotEmpty) {
      return explicitKey;
    }
    final accountId = await _storage.readAccountId();
    if (accountId == null || accountId.isEmpty) return null;
    return accountId;
  }

  Future<Database> _database() async {
    if (_db != null) return _db!;
    final databasesPath = await getDatabasesPath();
    final path = '$databasesPath/$_databaseName';
    _db = await openDatabase(
      path,
      version: 7,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tasksTable (
            id TEXT PRIMARY KEY,
            account_key TEXT NOT NULL,
            data TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_tasks_account ON $_tasksTable(account_key)');
        await db.execute('''
          CREATE TABLE $_operationsTable (
            id TEXT PRIMARY KEY,
            account_key TEXT NOT NULL,
            type TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_operations_account ON $_operationsTable(account_key)');
        await db.execute('''
          CREATE TABLE $_deletedTable (
            id TEXT PRIMARY KEY,
            account_key TEXT NOT NULL,
            deleted_at TEXT NOT NULL,
            sync_version INTEGER
          )
        ''');
        await db.execute('CREATE INDEX idx_deleted_account ON $_deletedTable(account_key)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 7) {
          final columns = await db.rawQuery('PRAGMA table_info($_deletedTable)');
          final hasSyncVersion = columns.any((column) => column['name'] == 'sync_version');
          if (!hasSyncVersion) {
            await db.execute('ALTER TABLE $_deletedTable ADD COLUMN sync_version INTEGER');
          }
        }
      },
    );
    return _db!;
  }

  @override
  Future<List<Task>> getTasks() async {
    final accountKey = await _accountKey();
    if (accountKey == null) return <Task>[];
    final db = await _database();
    final rows = await db.query(_tasksTable, where: 'account_key = ?', whereArgs: <Object>[accountKey]);
    return rows.map((row) => Task.fromJson(jsonDecode(row['data']! as String) as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveTask(Task task) async {
    final accountKey = await _accountKey();
    if (accountKey == null) return;
    final db = await _database();
    await db.insert(
      _tasksTable,
      <String, Object?>{'id': task.id, 'account_key': accountKey, 'data': jsonEncode(task.toJson())},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteTask(String id) async {
    final accountKey = await _accountKey();
    if (accountKey == null) return;
    final db = await _database();
    await db.delete(_tasksTable, where: 'id = ? AND account_key = ?', whereArgs: <Object>[id, accountKey]);
  }

  @override
  Future<void> markPendingUpsert(String id, DateTime updatedAt) async {
    final accountKey = await _accountKey();
    if (accountKey == null) return;
    final db = await _database();
    await db.insert(
      _operationsTable,
      <String, Object?>{'id': id, 'account_key': accountKey, 'type': 'upsert', 'updated_at': updatedAt.toUtc().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<PendingOperation>> getPendingOperations() async {
    final accountKey = await _accountKey();
    if (accountKey == null) return <PendingOperation>[];
    final db = await _database();
    final rows = await db.query(_operationsTable, where: 'account_key = ?', whereArgs: <Object>[accountKey]);
    return rows.map((row) => PendingOperation(id: row['id']! as String, type: (row['type'] as String) == 'delete' ? PendingOperationType.delete : PendingOperationType.upsert, updatedAt: DateTime.parse(row['updated_at']! as String))).toList();
  }

  @override
  Future<void> clearPendingOperation(String id) async {
    final accountKey = await _accountKey();
    if (accountKey == null) return;
    final db = await _database();
    await db.delete(_operationsTable, where: 'id = ? AND account_key = ?', whereArgs: <Object>[id, accountKey]);
  }

  @override
  Future<void> addPendingDelete(String id) async {
    final accountKey = await _accountKey();
    if (accountKey == null) return;
    final db = await _database();
    await db.insert(
      _deletedTable,
      <String, Object?>{'id': id, 'account_key': accountKey, 'deleted_at': DateTime.now().toUtc().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<String>> getPendingDeletes() async {
    final accountKey = await _accountKey();
    if (accountKey == null) return <String>[];
    final db = await _database();
    final rows = await db.query(_deletedTable, columns: <String>['id'], where: 'account_key = ?', whereArgs: <Object>[accountKey]);
    return rows.map((row) => row['id']! as String).toList();
  }

  Future<int?> getPendingDeleteVersion(String id) async {
    final accountKey = await _accountKey();
    if (accountKey == null) return null;
    final db = await _database();
    final rows = await db.query(_deletedTable, columns: <String>['sync_version'], where: 'id = ? AND account_key = ?', whereArgs: <Object>[id, accountKey], limit: 1);
    if (rows.isEmpty) return null;
    final value = rows.first['sync_version'];
    if (value == null) return null;
    return value is num ? value.toInt() : int.tryParse(value.toString());
  }

  @override
  Future<void> clearPendingDelete(String id) async {
    final accountKey = await _accountKey();
    if (accountKey == null) return;
    final db = await _database();
    await db.delete(_deletedTable, where: 'id = ? AND account_key = ?', whereArgs: <Object>[id, accountKey]);
  }

  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
