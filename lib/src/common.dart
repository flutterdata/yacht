part of yacht;

class Yacht {
  static late Isar _isar;
  static late Map<String, Repository> repositories;

  static final initialize =
      FutureProvider.family<void, List<Provider<Repository>>>(
          (ref, repositoryProviders) async {
    if (Isar.getInstance() != null) {
      return;
    }

    await Isar.initializeIsarCore(libraries: {
      Abi.macosX64: File('lib/support/libisar.dylib').absolute.path,
    });

    final _repositories = repositoryProviders.map(ref.read);
    final schemas = _repositories.map((r) => r._schema).toList();

    repositories = {
      for (final repository in _repositories)
        repository.internalType: repository,
    };

    _isar = await Isar.open(schemas, inspector: false);
  });

  static void clear() {
    _isar.writeTxnSync(() => _isar.clearSync());
  }

  static Future<void> dispose({bool destroy = false}) async {
    await _isar.close(deleteFromDisk: destroy);
    repositories.clear();
  }
}
