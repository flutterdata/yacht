import 'package:isar/isar.dart';
import 'package:meta/meta.dart';

import 'common.dart';
import 'repository.dart';

abstract class DataModel<T extends DataModel<T>> {
  Id _key = Isar.autoIncrement;
  Id get yachtKey => _key;
  @protected
  set yachtKey(Id value) => _key = value;

  Object? get id;

  Isar get _isar => Yacht.isar;

  String get _internalType => T.toString();

  @ignore
  bool get isNew => yachtKey == Isar.autoIncrement;

  @ignore
  bool get isSaved => repository.exists(id!);

  @ignore
  Repository<T> get repository =>
      Yacht.repositories[_internalType] as Repository<T>;

  T? reload() {
    return _isar.writeTxnSync(() => repository.collection.getSync(yachtKey));
  }

  T save() {
    if (isNew && id != null && isSaved) {
      this.yachtKey = repository.findOne(id!)!.yachtKey;
    }
    this.yachtKey = _isar.writeTxnSync(() {
      return repository.collection.putSync(this as T);
    });
    return this as T;
  }

  void delete() {
    final result =
        _isar.writeTxnSync(() => repository.collection.deleteSync(yachtKey));
    if (result == false) {
      throw Exception('Could not delete $this');
    }
  }

  T andKeyFrom(T model) {
    yachtKey = model.yachtKey;
    return this as T;
  }

  Map<String, dynamic> toJson() {
    if (isNew) {
      save();
    }
    final map =
        repository.collection.queryByKey(yachtKey).exportJsonSync().first;

    final links = repository.schema.getLinks(this as T);
    map.addAll({
      for (final link in links)
        (link as dynamic).linkName.toString(): link is IsarLink
            ? (link as dynamic).value.id
            : (link as dynamic).map((_) => _.id).toList(),
    });
    return map
      ..removeWhere((key, value) => value == null)
      ..remove('yachtKey')
      ..remove('hashCode');
  }

  // TODO remove
  static Id keyFor<T extends DataModel<T>>(T model) => model.yachtKey;
}
