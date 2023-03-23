part of yacht;

final kIdMapping = <Object, int>{};

abstract class DataModel<T extends DataModel<T>> {
  static final _uuid = uuid.Uuid();

  Id _key = _fastHash(_uuid.v1().substring(0, 8));

  Id get yachtKey {
    if (id != null) {
      return kIdMapping[id!] ??= _key;
    }
    return _key;
  }

  @protected
  set yachtKey(Id value) {
    _key = value;
  }

  Object? get id;

  Isar get _isar => repository.collection.isar;

  String get _internalType => T.toString();

  @ignore
  bool get isSaved => repository.exists(id!);

  @ignore
  Repository<T> get repository =>
      Yacht.repositories[_internalType] as Repository<T>;

  T? reload() {
    return _isar.writeTxnSync(() => repository.collection.getSync(yachtKey));
  }

  T save() {
    _isar.writeTxnSync(() {
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
    if (model.id != null && id != model.id) {
      throw UnsupportedError(
          'Cannot assign key for ID=${model.id} to target ID=$id');
    }
    if (id != null && kIdMapping[id!] != null) {
      throw UnsupportedError(
          'Cannot assign key to target with ID=$id that already has a key');
    }
    yachtKey = model.yachtKey;
    return this as T;
  }
}

/// FNV-1a 64bit hash algorithm optimized for Dart Strings
int _fastHash(String string) {
  var hash = 0xcbf29ce484222325;

  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }

  return hash;
}
