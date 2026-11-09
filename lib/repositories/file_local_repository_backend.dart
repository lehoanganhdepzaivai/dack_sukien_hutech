import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'local_repository_backend.dart';

typedef StorageDirectoryProvider = Future<Directory> Function();

/// Stores each value in its own file under the app support directory.
///
/// A temporary file and backup are used so an interrupted write cannot silently
/// replace the last complete event database with a partial JSON document.
class FileLocalRepositoryBackend implements LocalRepositoryBackend {
  FileLocalRepositoryBackend({StorageDirectoryProvider? directoryProvider})
    : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  final StorageDirectoryProvider _directoryProvider;
  Directory? _directory;

  @override
  Future<void> initialize() async {
    if (_directory != null) return;
    final supportDirectory = await _directoryProvider();
    final directory = Directory(
      '${supportDirectory.path}${Platform.pathSeparator}hutech_events',
    );
    await directory.create(recursive: true);
    _directory = directory;
  }

  @override
  Future<String?> read(String key) async {
    await initialize();
    final file = _fileFor(key);
    await _recoverInterruptedWrite(file);
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  @override
  Future<void> write(String key, String value) async {
    await initialize();
    final target = _fileFor(key);
    final temporary = File('${target.path}.tmp');
    final backup = File('${target.path}.bak');
    await _recoverInterruptedWrite(target);
    await temporary.writeAsString(value, flush: true);

    var movedPreviousValue = false;
    try {
      if (await backup.exists()) await backup.delete();
      if (await target.exists()) {
        await target.rename(backup.path);
        movedPreviousValue = true;
      }
      await temporary.rename(target.path);
    } catch (_) {
      if (!await target.exists() &&
          movedPreviousValue &&
          await backup.exists()) {
        await backup.rename(target.path);
      }
      rethrow;
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
    // The new file is already complete. A stale backup is harmless and can be
    // retried on the next write if Windows temporarily keeps it locked.
    try {
      if (await backup.exists()) await backup.delete();
    } on FileSystemException {
      // Keep the successful write even when backup cleanup is delayed.
    }
  }

  Future<void> _recoverInterruptedWrite(File target) async {
    if (await target.exists()) return;
    final backup = File('${target.path}.bak');
    final temporary = File('${target.path}.tmp');
    if (await backup.exists()) {
      await backup.rename(target.path);
      if (await temporary.exists()) await temporary.delete();
    } else if (await temporary.exists()) {
      await temporary.rename(target.path);
    }
  }

  File _fileFor(String key) {
    final safeKey = key.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return File('${_directory!.path}${Platform.pathSeparator}$safeKey.json');
  }
}
