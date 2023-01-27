import 'dart:ffi';
import 'dart:io';

import 'package:isar/isar.dart';

late Isar _isar;
Map<String, CollectionSchema> _schemas = {};

Future<void> initialize(
    {required List<CollectionSchema> schemas, bool clear = false}) async {
  await Isar.initializeIsarCore(libraries: {
    Abi.macosX64: File('lib/support/libisar.dylib').absolute.path
  });
  _schemas = {
    for (final schema in schemas) schema.name: schema,
  };
  _isar = await Isar.open(schemas);
  if (clear) {
    _isar.writeTxnSync(() => _isar.clearSync());
  }
}

class Repository<T extends DataModel<T>> {
  List<T> findAll() => collectionFor<T>().where().findAllSync();

  T? findOne(Object id) => collectionFor<T>().findById(id);

  void clear() => _isar.writeTxnSync(() => collectionFor<T>().clearSync());
}

mixin DataModel<T extends DataModel<T>> {
  Id _key = Isar.autoIncrement;

  Id get internalKey => _key;

  set __key(Id value) {
    this._key = value;
  }

  Object? get id;

  @ignore
  bool get isNew => _key == Isar.autoIncrement;

  @ignore
  IsarCollection<T> get collection => collectionFor<T>();

  T? reload() => _isar.writeTxnSync(() => collection.getSync(internalKey));

  T save() => _isar.writeTxnSync(() {
        this.__key = collection.putSync(this as T);
        return this as T;
      });

  void delete() => _isar.writeTxnSync(() => collection.deleteSync(internalKey));

  Map<String, dynamic> toJson() {
    if (isNew) {
      save();
    }
    final map =
        collectionFor<T>().findByKey(internalKey).exportJsonSync().first;
    final schema = _schemas[T.toString().capitalize()]! as CollectionSchema<T>;
    final links = schema.getLinks(this as T);
    map.addAll({
      for (final link in links)
        (link as dynamic).linkName.toString(): link is IsarLink
            ? (link as dynamic).value.id
            : (link as dynamic).map((_) => _.id).toList(),
    });
    return map
      ..removeWhere((key, value) => value == null)
      ..remove('internalKey');
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
    _isar.getCollectionByNameInternal(T.toString().capitalize())
        as IsarCollection<T>;

extension IsarCollectionX<T> on IsarCollection<T> {
  T? findById(Object id) => buildQuery<T>(whereClauses: [
        IndexWhereClause.equalTo(indexName: 'id', value: [id])
      ]).findFirstSync();

  Query<T> findByKey(int key) => buildQuery<T>(
      whereClauses: [IdWhereClause.between(lower: key, upper: key)]);
}
