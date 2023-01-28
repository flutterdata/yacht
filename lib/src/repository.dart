import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import 'package:meta/meta.dart';
import 'package:riverpod/riverpod.dart';

import 'common.dart';
import 'data_model.dart';
import 'notifier.dart';

abstract class Repository<T extends DataModel<T>> {
  /// Give access to the dependency injection system
  @nonVirtual
  final Ref ref;

  Repository(this.ref);

  CollectionSchema<T> get schema;

  String get internalType => T.toString();

  IsarCollection<T> get collection =>
      // ignore: invalid_use_of_protected_member
      Yacht.isar.getCollectionByNameInternal(internalType) as IsarCollection<T>;

  List<T> findAll() => collection.where().findAllSync();

  Future<T?> findOne(Object id) async {
    return collection.findById(id);
  }

  void clear() => Yacht.isar.writeTxnSync(() => collection.clearSync());

  // watchers

  ValueNotifier<List<T>> watchAll() {
    final notifier = ValueNotifier(findAll());
    final _sub = collection.watchLazy().listen((_) {
      notifier.updateWith(findAll());
    });
    notifier.onDispose = () => _sub.cancel();
    return notifier;
  }

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
  T? findById(Object id) => buildQuery<T>(whereClauses: [
        IndexWhereClause.equalTo(indexName: 'id', value: [id])
      ]).findFirstSync();

  Query<T> findByKey(int key) => buildQuery<T>(
      whereClauses: [IdWhereClause.between(lower: key, upper: key)]);
}
