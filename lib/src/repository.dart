part of yacht;

abstract class Repository<T extends DataModel<T>> {
  /// Give access to the dependency injection system
  @nonVirtual
  final Ref ref;

  Repository(this.ref);

  @protected
  CollectionSchema<T> get schema;

  // for use within library
  CollectionSchema<T> get _schema => schema;

  String get internalType => T.toString();

  IsarCollection<T> get collection =>
      // ignore: invalid_use_of_protected_member
      Yacht._isar.getCollectionByNameInternal(internalType)
          as IsarCollection<T>;

  List<T> findAll(
      {QueryBuilder<T, T, QQueryOperations> Function(
              QueryBuilder<T, T, QWhere>)?
          where}) {
    if (where != null) {
      return where(collection.where()).build().findAllSync();
    }
    return collection.where().findAllSync();
  }

  T? findOne(Object id) => collection.queryById(id).findFirstSync();

  bool exists(Object id) => collection.queryById(id).isNotEmptySync();

  void clear() => collection.isar.writeTxnSync(() => collection.clearSync());

  // watchers

  ValueNotifier<List<T>> watchAll() {
    final notifier = ValueNotifier(findAll());
    final _sub = collection.watchLazy().listen((_) {
      notifier.updateWith(findAll());
    });
    notifier.onDispose = () => _sub.cancel();
    return notifier;
  }

  ValueNotifier<T?> watchOne(T model) {
    final notifier = ValueNotifier<T?>(model);
    final _sub = collection.watchObjectLazy(model.yachtKey).listen((_) {
      notifier.updateWith(model.reload());
    });
    notifier.onDispose = () {
      return _sub.cancel();
    };
    return notifier;
  }

  // remote

  Future<String> zzz() async {
    final r = await httpClient.get(Uri.parse(baseUrl));
    return r.body;
  }

  //

  @protected
  String get baseUrl => 'https://override-base-url-in-adapter/';

  @protected
  @visibleForTesting
  http.Client get httpClient => http.Client();
}

extension IsarCollectionX<T> on IsarCollection<T> {
  Query<T> queryById(Object id) => buildQuery<T>(whereClauses: [
        IndexWhereClause.equalTo(indexName: 'id', value: [id])
      ]);

  Query<T> queryByKey(int key) => buildQuery<T>(
      whereClauses: [IdWhereClause.between(lower: key, upper: key)]);
}
