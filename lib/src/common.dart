import 'dart:ffi';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:riverpod/riverpod.dart';
import 'package:yacht/yacht.dart';

class Yacht {
  static late Isar isar;
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
    final schemas = _repositories.map((r) => r.schema).toList();

    repositories = {
      for (final repository in _repositories)
        repository.internalType: repository,
    };

    isar = await Isar.open(schemas, inspector: false);
  });

  static void clear() {
    isar.writeTxnSync(() => isar.clearSync());
  }

  static Future<void> dispose({bool destroy = false}) async {
    await isar.close(deleteFromDisk: destroy);
    repositories.clear();
  }
}
