import 'dart:ffi';
import 'dart:io';

import 'package:isar/isar.dart';

late Isar isar;

Future<void> initialize({required List<CollectionSchema> schemas}) async {
  await Isar.initializeIsarCore(libraries: {
    Abi.macosX64: File('lib/support/libisar.dylib').absolute.path
  });
  isar = await Isar.open(schemas);
}

class Repository<T extends DataModel<T>> {
  Future<List<T>> findAll() async {
    return await collectionFor<T>().where().findAll();
  }

  Future<T?> findOne(int id) async {
    return await collectionFor<T>().get(id) as T;
  }
}

mixin DataModel<T extends DataModel<T>> {
  int get id;

  @ignore
  IsarCollection<T> get collection => collectionFor<T>();

  Future<T?> reload() async {
    return await isar.writeTxn(() async => await collection.get(id));
  }

  Future<T?> save() async {
    await isar.writeTxn(() async => await collection.put(this as T));
    return this as T?;
  }

  Future<void> delete() async {
    await isar.writeTxn(() async => await collection.delete(id));
  }
}

class DataRepository {
  final List<Type> adapters;
  final bool remote;
  const DataRepository(this.adapters, {this.remote = true});
}

extension StringUtilsX on String {
  String capitalize() =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';
}

IsarCollection<T> collectionFor<T>() =>
    // ignore: invalid_use_of_protected_member
    isar.getCollectionByNameInternal(T.toString().capitalize())
        as IsarCollection<T>;
