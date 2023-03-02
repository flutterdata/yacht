part of yacht;

abstract class Repository<T extends DataModel<T>> = _BaseAdapter<T>
    with _FinderAdapter<T>, _WatcherAdapter<T>;

abstract class _BaseAdapter<T extends DataModel<T>> {
  /// Give access to the dependency injection system
  @nonVirtual
  final Ref ref;

  _BaseAdapter(this.ref);

  @protected
  CollectionSchema<T> get schema;

  // for use within library
  CollectionSchema<T> get _schema => schema;

  String get internalType => T.toString();

  IsarCollection<T> get collection =>
      // ignore: invalid_use_of_protected_member
      Yacht._isar.getCollectionByNameInternal(internalType)
          as IsarCollection<T>;

  _RemoteAdapter get async =>
      _RemoteAdapter<T>(repository: this as Repository<T>);
}

mixin _FinderAdapter<T extends DataModel<T>> on _BaseAdapter<T> {
  List<T> findAll(
      {QueryBuilder<T, T, QQueryOperations> Function(
              QueryBuilder<T, T, QWhere>)?
          where}) {
    if (where != null) {
      return where(super.collection.where()).build().findAllSync();
    }
    return super.collection.where().findAllSync();
  }

  T? findOne(Object id) => super.collection.queryById(id).findFirstSync();

  bool exists(Object id) => super.collection.queryById(id).isNotEmptySync();

  void clear() =>
      super.collection.isar.writeTxnSync(() => super.collection.clearSync());
}

mixin _WatcherAdapter<T extends DataModel<T>> on _FinderAdapter<T> {
  ValueNotifier<List<T>> watchAll(
      {QueryBuilder<T, T, QQueryOperations> Function(
              QueryBuilder<T, T, QWhere>)?
          where}) {
    final notifier = ValueNotifier(findAll(where: where));
    late StreamSubscription _sub;

    if (where == null) {
      _sub = super.collection.watchLazy().listen((_) {
        notifier.updateWith(findAll());
      });
    } else {
      _sub = where(super.collection.where()).watch().listen((results) {
        notifier.updateWith(results);
      });
    }

    notifier.onDispose = () => _sub.cancel();
    return notifier;
  }

  ValueNotifier<T?> watchOne(T model) {
    final notifier = ValueNotifier<T?>(model);
    final _sub = super.collection.watchObjectLazy(model.yachtKey).listen((_) {
      notifier.updateWith(model.reload());
    });
    notifier.onDispose = () {
      return _sub.cancel();
    };
    return notifier;
  }
}

extension IsarCollectionX<T> on IsarCollection<T> {
  Query<T> queryById(Object id) => buildQuery<T>(whereClauses: [
        IndexWhereClause.equalTo(indexName: 'id', value: [id])
      ]);

  Query<T> queryByKey(int key) => buildQuery<T>(
      whereClauses: [IdWhereClause.between(lower: key, upper: key)]);
}

/// A utility class used to return deserialized main [models] AND [included] models.
class DeserializedData<T extends DataModel<T>> {
  const DeserializedData(this.models, {this.included = const []});
  final List<T> models;
  final List<DataModel> included;
  T? get model => models.singleOrNull;
}
