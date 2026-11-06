import 'package:drift/wasm.dart';
import 'store.dart';

const databasePrefix = 'focus_clock_spike_';

void requireSafeStorage(WasmStorageImplementation implementation) {
  if (implementation == WasmStorageImplementation.inMemory ||
      implementation == WasmStorageImplementation.unsafeIndexedDb) {
    throw UnsupportedError(
      'Durable synchronized storage required; rejected ${implementation.name}. '
      'Use a browser with SharedWorker support, or serve COOP/COEP for OPFS.',
    );
  }
}

Future<WasmProbeResult> probe(String name) {
  if (!name.startsWith(databasePrefix)) {
    throw ArgumentError('Only isolated spike database names are allowed');
  }
  return WasmDatabase.probe(
    databaseName: name,
    // Dart test serves the package below a per-run path prefix.
    sqlite3Uri: Uri.base.resolve('../web/sqlite3.wasm'),
    driftWorkerUri: Uri.base.resolve('../web/drift_worker.js'),
  );
}

Future<({SpikeStore db, WasmStorageImplementation mode})> openStore(
  String name,
) async {
  final capabilities = await probe(name);
  final existing = capabilities.existingDatabases.where((db) => db.$2 == name);
  final candidates =
      capabilities.availableStorages
          .where(
            (mode) =>
                existing.isEmpty ||
                existing.any((db) => db.$1 == mode.storageApi),
          )
          .toList()
        ..sort((a, b) => a.index.compareTo(b.index));
  final mode = candidates.firstOrNull ?? WasmStorageImplementation.inMemory;
  // Guard before opening the database or running schema/data writes.
  requireSafeStorage(mode);
  final connection = await capabilities.open(mode, name);
  return (db: SpikeStore(connection), mode: mode);
}

Future<void> deleteStore(String name) async {
  final capabilities = await probe(name);
  for (final db in capabilities.existingDatabases.where(
    (db) => db.$2 == name,
  )) {
    await capabilities.deleteDatabase(db);
  }
}
