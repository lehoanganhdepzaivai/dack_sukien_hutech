import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'local_repository_backend.dart';
import 'local_repository_backend_stub.dart'
    if (dart.library.io) 'local_repository_backend_io.dart'
    if (dart.library.js_interop) 'local_repository_backend_web.dart'
    as backend_factory;

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();

/// Durable local event data. No credentials are persisted.
///
/// Web builds use IndexedDB so uploaded data images are not constrained by the
/// small SharedPreferences/localStorage quota. Native builds use an app-support
/// JSON file. The previous SharedPreferences value is imported on first use.
class LocalRepository {
  static const dataKey = 'hutech_events.local.v1';
  static const recoveryKey = '$dataKey.recovery';

  LocalRepository({
    LocalRepositoryBackend? backend,
    SharedPreferencesLoader? preferencesLoader,
  }) : _backend = backend ?? backend_factory.createLocalRepositoryBackend(),
       _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  final LocalRepositoryBackend _backend;
  final SharedPreferencesLoader _preferencesLoader;
  SharedPreferences? _preferences;
  String? _lastRaw;

  Future<void> initialize() async {
    await _backend.initialize();
    _preferences ??= await _preferencesLoader();
  }

  Future<Map<String, dynamic>?> read() async {
    await initialize();
    var raw = await _backend.read(dataKey);
    if (raw == null) {
      raw = _preferences!.getString(dataKey);
      if (raw != null) {
        // Copy the exact legacy value before parsing. Corrupt legacy data can
        // therefore still be recovered byte-for-byte.
        await _backend.write(dataKey, raw);
      }
    }
    _lastRaw = raw;
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Dữ liệu đã lưu không phải đối tượng JSON.');
    }
    return decoded;
  }

  /// Preserve the exact unreadable value before any later user action replaces it.
  Future<void> preserveRecovery() async {
    await initialize();
    final raw =
        _lastRaw ??
        await _backend.read(dataKey) ??
        _preferences!.getString(dataKey);
    if (raw == null) return;

    await _backend.write(recoveryKey, raw);
    // Keep the old recovery slot populated as well, so users upgrading from an
    // earlier build retain the same emergency recovery path.
    final saved = await _preferences!.setString(recoveryKey, raw);
    if (!saved) {
      throw StateError('Không thể giữ bản phục hồi dữ liệu cục bộ.');
    }
  }

  Future<void> save(Map<String, dynamic> data) async {
    await initialize();
    final raw = jsonEncode(data);
    await _backend.write(dataKey, raw);
    _lastRaw = raw;
  }
}
