import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../auth/data/token_storage.dart';
import '../domain/task.dart';
import 'sync_metadata_store.dart';
import 'task_repository.dart';

class LocalTaskDatabase implements TaskRepository, SyncMetadataStore {
  LocalTaskDatabase({String? accountKey, TokenStorage? storage}) : _accountKeyValue = accountKey, _storage = storage ?? const TokenStorage();

  final String? _accountKeyValue;
  final TokenStorage _storage;
  Database? _db;
  static const String _databaseName = 'todo_mobile.db';
  static const String _tasksTable = 'tasks';
  static const String _operationsTable = 'pending_operations';
  static const String _deletedTable = 'pending_deletes';
  static const Uuid _uuid = Uuid();

  Future<String?> _accountKey() async {
    final explicitKey = _accountKeyValue;
    if (explicitKey != null && explicitKey.isNotEmpty) return explicitKey;
    return await _storage.readAccountId();
  }

  Future<Database> _database() async {
    if (_db != null) return _db!;
    final databasesPath = await getDatabasesPath();
    _db = await openDatabase('$databasesPath/$_databaseName', version: 8, onCreate: (db, version) async {
      await db.execute('CREATE TABLE $_tasksTable (id TEXT PRIMARY KEY, account_key TEXT NOT NULL, data TEXT NOT NULL)');
      await db.execute('CREATE INDEX idx_tasks_account ON $_tasksTable(account_key)');
      await db.execute('CREATE TABLE $_operationsTable (id TEXT PRIMARY KEY, account_key TEXT NOT NULL, type TEXT NOT NULL, updated_at TEXT NOT NULL, operation_id TEXT)');
      await db.execute('CREATE INDEX idx_operations_account ON $_operationsTable(account_key)');
      await db.execute('CREATE TABLE $_deletedTable (id TEXT PRIMARY KEY, account_key TEXT NOT NULL, deleted_at TEXT NOT NULL, sync_version INTEGER, operation_id TEXT)');
      await db.execute('CREATE INDEX idx_deleted_account ON $_deletedTable(account_key)');
    }, onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 7) {
        final columns = await db.rawQuery('PRAGMA table_info($_deletedTable)');
        if (!columns.any((column) => column['name'] == 'sync_version')) await db.execute('ALTER TABLE $_deletedTable ADD COLUMN sync_version INTEGER');
      }
      if (oldVersion < 8) {
        final operationColumns = await db.rawQuery('PRAGMA table_info($_operationsTable)');
        if (!operationColumns.any((column) => column['name'] == 'operation_id')) await db.execute('ALTER TABLE $_operationsTable ADD COLUMN operation_id TEXT');
        final deleteColumns = await db.rawQuery('PRAGMA table_info($_deletedTable)');
        if (!deleteColumns.any((column) => column['name'] == 'operation_id')) await db.execute('ALTER TABLE $_deletedTable ADD COLUMN operation_id TEXT');
        await db.execute('UPDATE $_operationsTable SET operation_id = id WHERE operation_id IS NULL');
        await db.execute('UPDATE $_deletedTable SET operation_id = id WHERE operation_id IS NULL');
      }
    });
    return _db!;
  }

  @override
  Future<List<Task>> getTasks() async {
    final accountKey = await _accountKey();
    if (accountKey == null || accountKey.isEmpty) return <Task>[];
    final rows = await (await _database()).query(_tasksTable, where: 'account_key = ?', whereArgs: <Object>[accountKey]);
    return rows.map((row) => Task.fromJson(jsonDecode(row['data']! as String) as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveTask(Task task) async {
    final accountKey = await _accountKey();
    if (accountKey == null || accountKey.isEmpty) return;
    await (await _database()).insert(_tasksTable, <String, Object?>{'id': task.id, 'account_key': accountKey, 'data': jsonEncode(task.toJson())}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> deleteTask(String id) async {
    final accountKey = await _accountKey();
    if (accountKey == null || accountKey.isEmpty) return;
    await (await _database()).delete(_tasksTable, where: 'id = ? AND account_key = ?', whereArgs: <Object>[id, accountKey]);
  }

  @override
  Future<void> markPendingUpsert(String id, DateTime updatedAt, {String? operationId}) async {
    final accountKey = await _accountKey();
    if (accountKey == null || accountKey.isEmpty) return;
    await (await _database()).insert(_operationsTable, <String, Object?>{'id': id, 'account_key': accountKey, 'type': 'upsert', 'updated_at': updatedAt.toUtc().toIso8601String(), 'operation_id': operationId ?? _uuid.v4()}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<PendingOperation>> getPendingOperations() async {
    final accountKey = await _accountKey();
    if (accountKey == null || accountKey.isEmpty) return <PendingOperation>[];
    final rows = await (await _database()).query(_operationsTable, where: 'account_key = ?', whereArgs: <Object>[accountKey]);
    return rows.map((row) => PendingOperation(id: row['id']! as String, type: row['type'] == 'delete' ? PendingOperationType.delete : PendingOperationType.upsert, updatedAt: DateTime.parse(row['updated_at']! as String), operationId: row['operation_id'] as String?)).toList();
  }

  @override
  Future<void> clearPendingOperation(String id) async {
    final accountKey = await _accountKey();
    if (accountKey == null || accountKey.isEmpty) return;
    await (await _database()).delete(_operationsTable, where: 'id = ? AND account_key = ?', whereArgs: <Object>[id, accountKey]);
  }

  @override
  Future<void> clearPendingOperationIfMatches(String id, String? operationId) async {
    final accountKey = await _accountKey();
    if (accountKey == null || accountKey.isEmpty || operationId == null || operationId.isEmpty) return;
    await (await _database()).delete(_operationsTable, where: 'id = ? AND account_key = ? AND operation_id = ?', whereArgs: <Object>[id, accountKey, operationId]);
  }

  @override
  Future<void> addPendingDelete(String id, {String? operationId}) async {
    final accountKey = await _accountKey();
    if (accountKey == null || accountKey.isEmpty) return;
    await (await _database()).insert(_deletedTable, <String, Object?>{'id': id, 'account_key': accountKey, 'deleted_at': DateTime.now().toUtc().toIso8601String(), 'operation_id': operationId ?? _uuid.v4()}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<String>> getPendingDeletes() async {
    final accountKey = await _accountKey();
    if (accountKey == null || accountKey.isEmpty) return <String>[];
    final rows = await (await _database()).query(_deletedTable, columns: <String>['id'], where: 'account_key = ?', whereArgs: <Object>[accountKey]);
    return rows.map((row) => row['id']! as String).toList();
  }

  Future<int?> getPendingDeleteVersion(String id) async {
    final accountKey = await _accountKey();
    if (accountKey == null || accountKey.isEmpty) return null;
    final rows = await (await _database()).query(_deletedTable, columns: <String>['sync_version'], where: 'id = ? AND account_key = ?', whereArgs: <Object>[id, accountKey], limit: 1);
    if (rows.isEmpty || rows.first['sync_version'] == null) return null;
    final value = rows.first['sync_version'];
    return value is num ? value.toInt() : int.tryParse(value.toString());
  }

  @override
  Future<String?> getPendingDeleteOperationId(String id) async {
    final accountKey = await _accountKey();
    if (accountKey == null || accountKey.isEmpty) return null;
    final rows = await (await _database()).query(_deletedTable, columns: <String>['operation_id'], where: 'id = ? AND account_key = ?', whereArgs: <Object>[id, accountKey], limit: 1);
    return rows.isEmpty ? null : rows.first['operation_id'] as String?;
  }

  @override
  Future<void> clearPendingDelete(String id) async {
    final accountKey = await _accountKey();
    if (accountKey == null || accountKey.isEmpty) return;
    await (await _database()).delete(_deletedTable, where: 'id = ? AND account_key = ?', whereArgs: <Object>[id, accountKey]);
  }

  @override
  Future<void> clearPendingDeleteIfMatches(String id, String? operationId) async {
    final accountKey = await _accountKey();
    if (accountKey == null || accountKey.isEmpty || operationId == null || operationId.isEmpty) return;
    await (await _database()).delete(_deletedTable, where: 'id = ? AND account_key = ? AND operation_id = ?', whereArgs: <Object>[id, accountKey, operationId]);
  }

  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
