/// Raw durable storage used by [LocalRepository].
///
/// Values stay as strings so malformed legacy JSON can be copied byte-for-byte
/// into the recovery slot before the application replaces it.
abstract interface class LocalRepositoryBackend {
  Future<void> initialize();

  Future<String?> read(String key);

  Future<void> write(String key, String value);
}
