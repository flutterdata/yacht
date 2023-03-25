part of yacht;

abstract class Repository<T extends DataModel<T>> = _BaseAdapter<T>
    with
        _FinderAdapter<T>,
        _SerializationAdapter<T>,
        _RemoteAdapter<T>,
        _WatcherAdapter<T>;

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

mixin _SerializationAdapter<T extends DataModel<T>> on _FinderAdapter<T> {
  Future<Map<String, dynamic>> serialize(T model) async {
    model.save();

    final map = collection.queryByKey(model.yachtKey).exportJsonSync().first;

    final links = schema.getLinks(model);
    map.addAll({
      for (final link in links)
        (link as dynamic).linkName.toString(): link is IsarLink
            ? (link as dynamic).value?.id
            : (link as dynamic).map((_) => _.id).toList(),
    });
    return map
      ..removeWhere((key, value) => value == null)
      ..remove('yachtKey')
      ..remove('hashCode');
  }

  Future<T> deserialize(Map<String, dynamic> data) async {
    await collection.isar.writeTxn(() => collection.importJson([data]));
    return collection.queryById(data['id'].toString()).findAllSync().first;
  }
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
  Query<T> queryById(Object id) {
    final hasIndex = schema.indexes[r'id'] != null;
    return buildQuery<T>(
      whereClauses: [
        if (hasIndex) IndexWhereClause.equalTo(indexName: 'id', value: [id])
      ],
      filter: FilterGroup.and(
          [if (!hasIndex) FilterCondition.equalTo(property: r'id', value: id)]),
    );
  }

  Query<T> queryByKey(int key) => buildQuery<T>(
      whereClauses: [IdWhereClause.between(lower: key, upper: key)]);
}

class DataRepository {
  final List<Type> adapters;
  const DataRepository(this.adapters);
}
