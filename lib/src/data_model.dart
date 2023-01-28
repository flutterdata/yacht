import 'package:isar/isar.dart';
import 'package:yacht/yacht.dart';

mixin DataModel<T extends DataModel<T>> {
  Id _key = Isar.autoIncrement;

  Id get internalKey => _key;

  set __key(Id value) {
    this._key = value;
  }

  Object? get id;

  Isar get _isar => Yacht.isar;

  String get _internalType => T.toString();

  @ignore
  Repository<T> get repository =>
      Yacht.repositories[_internalType] as Repository<T>;

  @ignore
  bool get isNew => _key == Isar.autoIncrement;

  T? reload() =>
      _isar.writeTxnSync(() => repository.collection.getSync(internalKey));

  T save() => _isar.writeTxnSync(() {
        this.__key = repository.collection.putSync(this as T);
        return this as T;
      });

  void delete() =>
      _isar.writeTxnSync(() => repository.collection.deleteSync(internalKey));

  Map<String, dynamic> toJson() {
    if (isNew) {
      save();
    }
    final map =
        repository.collection.findByKey(internalKey).exportJsonSync().first;

    final links = repository.schema.getLinks(this as T);
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
