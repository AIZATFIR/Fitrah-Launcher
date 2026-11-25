import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:isar_community/isar.dart';

import 'focus_store.dart';
import 'live_model_codec.dart';

class _RecordsDatabase extends GeneratedDatabase {
  _RecordsDatabase(super.connection) : super.connect();
  @override
  int get schemaVersion => 1;
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => const [];
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) async {
      await customStatement(
        'CREATE TABLE records (collection TEXT NOT NULL, id INTEGER NOT NULL, payload TEXT NOT NULL, PRIMARY KEY(collection, id))',
      );
      await customStatement(
        'CREATE TABLE counters (collection TEXT PRIMARY KEY, next_id INTEGER NOT NULL)',
      );
      await customStatement(
        'CREATE TABLE recovery (id INTEGER PRIMARY KEY CHECK(id=1), payload TEXT NOT NULL)',
      );
    },
    onUpgrade: (_, from, to) async =>
        throw StateError('Unsupported storage version $from'),
    beforeOpen: (details) async {
      if (details.versionBefore != null &&
          details.versionBefore! > schemaVersion) {
        throw StateError('This database needs a newer app version');
      }
    },
  );
}

/// All related writes and monotonic ID reservations share SQLite's transaction.
class BrowserFocusStore extends FocusStore implements RecoveryJournal {
  BrowserFocusStore._(this._db, this.mode);
  final _RecordsDatabase _db;
  final WasmStorageImplementation mode;
  final Object _transactionKey = Object();
  final Object _undoKey = Object();
  @override
  bool get isDurable => true;

  static Future<BrowserFocusStore> open({
    String name = 'focus_clock_production_v1',
  }) async {
    final probe = await WasmDatabase.probe(
      databaseName: name,
      sqlite3Uri: Uri.base.resolve('sqlite3.wasm'),
      driftWorkerUri: Uri.base.resolve('drift_worker.js'),
    );
    final existing = probe.existingDatabases
        .where((entry) => entry.$2 == name)
        .toList();
    final modes =
        probe.availableStorages
            .where(
              (mode) =>
                  mode != WasmStorageImplementation.inMemory &&
                  mode != WasmStorageImplementation.unsafeIndexedDb &&
                  (existing.isEmpty ||
                      existing.any((entry) => entry.$1 == mode.storageApi)),
            )
            .toList()
          ..sort((a, b) => a.index.compareTo(b.index));
    if (modes.isEmpty) {
      throw UnsupportedError(
        'Durable browser storage is unavailable. Try a supported browser.',
      );
    }
    final db = _RecordsDatabase(await probe.open(modes.first, name));
    try {
      // Force opening and schema validation before production can render Home.
      await db.customSelect('SELECT count(*) AS n FROM records').getSingle();
      return BrowserFocusStore._(db, modes.first);
    } catch (_) {
      await db.close();
      rethrow;
    }
  }

  bool get _inTransaction => Zone.current[_transactionKey] != null;
  void _requireWrite() {
    if (Zone.current[_transactionKey] != true) {
      throw StateError('A write transaction is required');
    }
  }

  @override
  Future<R> txn<R>(Future<R> Function() action) => _transaction(false, action);
  @override
  Future<R> writeTxn<R>(Future<R> Function() action) =>
      _transaction(true, action);
  Future<R> _transaction<R>(bool write, Future<R> Function() action) async {
    if (_inTransaction) {
      throw StateError('Nested storage transactions are not supported');
    }
    final undo = <void Function()>[];
    try {
      return await _db.transaction(
        () => runZoned(
          action,
          zoneValues: {_transactionKey: write, _undoKey: undo},
        ),
      );
    } catch (_) {
      for (final restore in undo.reversed) {
        restore();
      }
      rethrow;
    }
  }

  T _decode<T>(QueryRow row) {
    final payload =
        jsonDecode(row.read<String>('payload')) as Map<String, dynamic>;
    final value = LiveModelCodec.decode<T>(payload);
    final id = row.read<int>('id');
    LiveModelCodec.validateId(id);
    if (LiveModelCodec.id(value as Object) != id) {
      throw const FormatException('Mismatched live row ID');
    }
    return value;
  }

  @override
  Future<List<T>> all<T>() async =>
      (await _db
              .customSelect(
                'SELECT id,payload FROM records WHERE collection = ? ORDER BY id',
                variables: [Variable(LiveModelCodec.collectionFor<T>())],
              )
              .get())
          .map(_decode<T>)
          .toList();
  @override
  Future<T?> get<T>(int id) async {
    LiveModelCodec.validateId(id);
    final row = await _db
        .customSelect(
          'SELECT id,payload FROM records WHERE collection = ? AND id = ?',
          variables: [
            Variable(LiveModelCodec.collectionFor<T>()),
            Variable(id),
          ],
        )
        .getSingleOrNull();
    return row == null ? null : _decode<T>(row);
  }

  @override
  Future<int> put<T>(T value) async {
    _requireWrite();
    final row = value as Object;
    final collection = LiveModelCodec.collectionFor<T>();
    var id = LiveModelCodec.id(row);
    final counter = await _db
        .customSelect(
          'SELECT next_id FROM counters WHERE collection = ?',
          variables: [Variable(collection)],
        )
        .getSingleOrNull();
    var next = counter?.read<int>('next_id') ?? 1;
    LiveModelCodec.validateId(next);
    if (id == Isar.autoIncrement) id = next;
    LiveModelCodec.validateId(id);
    if (id >= next) next = id + 1;
    LiveModelCodec.validateId(next);
    final previousId = LiveModelCodec.id(row);
    (Zone.current[_undoKey] as List<void Function()>).add(
      () => LiveModelCodec.setId(row, previousId),
    );
    LiveModelCodec.setId(row, id);
    String payload;
    try {
      payload = jsonEncode(LiveModelCodec.encode(row));
    } catch (_) {
      LiveModelCodec.setId(row, previousId);
      rethrow;
    }
    await _db.customStatement(
      'INSERT INTO counters(collection,next_id) VALUES(?,?) ON CONFLICT(collection) DO UPDATE SET next_id=excluded.next_id',
      [collection, next],
    );
    await _db.customStatement(
      'INSERT INTO records(collection,id,payload) VALUES(?,?,?) ON CONFLICT(collection,id) DO UPDATE SET payload=excluded.payload',
      [collection, id, payload],
    );
    _db.notifyUpdates({const TableUpdate('records')});
    return id;
  }

  @override
  Future<bool> delete<T>(int id) async {
    _requireWrite();
    LiveModelCodec.validateId(id);
    final count = await _db.customUpdate(
      'DELETE FROM records WHERE collection = ? AND id = ?',
      variables: [Variable(LiveModelCodec.collectionFor<T>()), Variable(id)],
    );
    _db.notifyUpdates({const TableUpdate('records')});
    return count > 0;
  }

  @override
  Future<void> clear() async {
    _requireWrite();
    await _db.customStatement('DELETE FROM records');
    _db.notifyUpdates({const TableUpdate('records')});
  }

  @override
  Stream<void> watch() async* {
    // Subscribe before the first snapshot to avoid losing a concurrent commit.
    final controller = StreamController<void>();
    final subscription = _db
        .tableUpdates(TableUpdateQuery.onTableName('records'))
        .listen((_) => controller.add(null), onError: controller.addError);
    controller.add(null);
    try {
      yield* controller.stream;
    } finally {
      await subscription.cancel();
      await controller.close();
    }
  }

  @override
  Future<String> saveRecovery(Uint8List bytes) async {
    await writeTxn(() async {
      await _db.customStatement(
        'INSERT INTO recovery(id,payload) VALUES(1,?) ON CONFLICT(id) DO UPDATE SET payload=excluded.payload',
        [utf8.decode(bytes)],
      );
    });
    return 'Salinan pemulihan di Pengaturan';
  }

  @override
  Future<Uint8List?> latestRecovery() async {
    final row = await _db
        .customSelect('SELECT payload FROM recovery WHERE id=1')
        .getSingleOrNull();
    return row == null
        ? null
        : Uint8List.fromList(utf8.encode(row.read<String>('payload')));
  }

  @override
  Future<void> close() => _db.close();
}
