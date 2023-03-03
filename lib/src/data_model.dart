part of yacht;

abstract class DataModel<T extends DataModel<T>> {
  Id _key = Isar.autoIncrement;
  Id get yachtKey => _key;
  @protected
  set yachtKey(Id value) => _key = value;

  Object? get id;

  Isar get _isar => repository.collection.isar;

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
}
