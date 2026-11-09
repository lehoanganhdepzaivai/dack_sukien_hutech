import 'package:idb_shim/idb.dart';

import 'local_repository_backend.dart';

/// IndexedDB key-value storage for the web build.
class IndexedDbLocalRepositoryBackend implements LocalRepositoryBackend {
  IndexedDbLocalRepositoryBackend({
    required this.factory,
    this.databaseName = 'hutech_events',
  });

  static const _storeName = 'local_state';

  final IdbFactory factory;
  final String databaseName;
  Database? _database;

  @override
  Future<void> initialize() async {
    _database ??= await factory.open(
      databaseName,
      version: 1,
      onUpgradeNeeded: (event) {
        if (!event.database.objectStoreNames.contains(_storeName)) {
          event.database.createObjectStore(_storeName);
        }
      },
    );
  }

  @override
  Future<String?> read(String key) async {
    await initialize();
    final transaction = _database!.transaction(_storeName, idbModeReadOnly);
    final value = await transaction.objectStore(_storeName).getObject(key);
    await transaction.completed;
    if (value == null) return null;
    if (value is! String) {
      throw const FormatException('Dữ liệu IndexedDB không phải chuỗi JSON.');
    }
    return value;
  }

  @override
  Future<void> write(String key, String value) async {
    await initialize();
    final transaction = _database!.transaction(_storeName, idbModeReadWrite);
    await transaction.objectStore(_storeName).put(value, key);
    await transaction.completed;
  }
}
