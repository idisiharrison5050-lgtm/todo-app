import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../domain/task.dart';
import 'sync_metadata_store.dart';
import 'task_repository.dart';

class LocalTaskDatabase implements TaskRepository, SyncMetadataStore {
  LocalTaskDatabase({required this.accountKey});

  final String accountKey;
  Database? _database;
  static const String _databaseName = 'todo_mobile.db';
  static const String _tasksTable = 'tasks';
  static const String _operationsTable = 'pending_operations';
  static const String _deletedTable = 'pending_deletes';

  Future<String> _accountKey() async => accountKey;

  Future<Database> get _db async {
    if (_database != null) return _database!;
    final path = p.join(await getDatabasesPath(), _databaseName);
    _database = await openDatabase(path, version: 7, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE $_tasksTable (
          id TEXT PRIMARY KEY,
          account_key TEXT NOT NULL,
          payload TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE $_operationsTable (
          id TEXT PRIMARY KEY,
          account_key TEXT NOT NULL,
          type TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE $_deletedTable (
          id TEXT PRIMARY KEY,
          account_key TEXT NOT NULL,
          deleted_at INTEGER NOT NULL,
          sync_version INTEGER
        )
      ''');
    }, onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 7) {
        await db.execute('ALTER TABLE $_deletedTable ADD COLUMN sync_version INTEGER');
      }
    });
    return _database!;
  }

  @override
  Future<List<Task>> getTasks() async {
    final key = await _accountKey();
    final rows = await (await _db).query(
      _tasksTable,
      columns: ['payload'],
      where: 'account_key = ?',
      whereArgs: [key],
      orderBy: 'updated_at DESC',
    );
    return rows
        .map((row) => Task.fromJson(jsonDecode(row['payload']! as String) as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<void> saveTask(Task task) async {
    final key = await _accountKey();
    final payload = jsonEncode(task.toJson());
    await (await _db).insert(
      _tasksTable,
      {
        'id': task.id,
        'account_key': key,
        'payload': payload,
        'updated_at': task.updatedAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteTask(String id) async {
    final key = await _accountKey();
    await (await _db).delete(
      _tasksTable,
      where: 'id = ? AND account_key = ?',
      whereArgs: [id, key],
    );
  }

  @override
  Future<void> addPendingUpsert(String id, DateTime updatedAt) async {
    final key = await _accountKey();
    await (await _db).insert(
      _operationsTable,
      {
        'id': id,
        'account_key': key,
        'type': PendingOperationType.upsert.name,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> addPendingDelete(String id) async {
    final key = await _accountKey();
    final db = await _db;
    final rows = await db.query(
      _tasksTable,
      columns: ['payload'],
      where: 'id = ? AND account_key = ?',
      whereArgs: [id, key],
      limit: 1,
    );
    int? syncVersion;
    if (rows.isNotEmpty) {
      final payload = jsonDecode(rows.first['payload']! as String) as Map<String, dynamic>;
      syncVersion = (payload['syncVersion'] as num?)?.toInt();
    }
    await db.insert(
      _deletedTable,
      {
        'id': id,
        'account_key': key,
        'deleted_at': DateTime.now().millisecondsSinceEpoch,
        'sync_version': syncVersion,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.delete(
      _operationsTable,
      where: 'id = ? AND account_key = ?',
      whereArgs: [id, key],
    );
  }

  @override
  Future<List<String>> getPendingDeletes() async {
    final key = await _accountKey();
    final rows = await (await _db).query(
      _deletedTable,
      columns: ['id'],
      where: 'account_key = ?',
      whereArgs: [key],
      orderBy: 'deleted_at ASC',
    );
    return rows.map((row) => row['id']! as String).toList(growable: false);
  }

  Future<int?> getPendingDeleteVersion(String id) async {
    final key = await _accountKey();
    final rows = await (await _db).query(
      _deletedTable,
      columns: ['sync_version'],
      where: 'id = ? AND account_key = ?',
      whereArgs: [id, key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['sync_version'] as int?;
  }

  @override
  Future<void> clearPendingDelete(String id) async {
    final key = await _accountKey();
    await (await _db).delete(
      _deletedTable,
      where: 'id = ? AND account_key = ?',
      whereArgs: [id, key],
    );
  }

  @override
  Future<List<PendingOperation>> getPendingOperations() async {
    final key = await _accountKey();
    final rows = await (await _db).query(
      _operationsTable,
      where: 'account_key = ?',
      whereArgs: [key],
      orderBy: 'updated_at ASC',
    );
    return rows.map((row) => PendingOperation(
      id: row['id']! as String,
      type: PendingOperationType.values.byName(row['type']! as String),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at']! as int),
    )).toList(growable: false);
  }

  @override
  Future<void> clearPendingOperation(String id) async {
    final key = await _accountKey();
    await (await _db).delete(
      _operationsTable,
      where: 'id = ? AND account_key = ?',
      whereArgs: [id, key],
    );
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
