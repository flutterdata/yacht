part of yacht;

abstract class DataModel<T extends DataModel<T>> {
  static final _uuid = uuid.Uuid();

  static Id getKeyForId(Object id) => _fastHash(id.toString());

  late final Id _key;

  DataModel() {
    if (id != null) {
      _key = getKeyForId(id!);
    } else {
      _key = _fastHash(_uuid.v1().substring(0, 8));
    }
  }

  T init() {
    // init relationships

    final metadatas = repository.relationshipMetas.values;
    for (final metadata in metadatas) {
      final relationship = metadata.instance(this);
      relationship?._init(
        owner: this,
        name: metadata.name,
        inverseName: metadata.inverseName,
      );
    }
    return this as T;
  }

  Id get yachtKey => _key;

  Object? get id;

  Isar get _isar => repository.collection.isar;

  String get _internalType => T.toString();

  @ignore
  bool get isSaved => repository.exists(id!);

  @ignore
  Repository<T> get repository =>
      Yacht.repositories[_internalType] as Repository<T>;

  T? reload() {
    return repository.collection.getSync(yachtKey)?.init();
  }

  T save() {
    init();
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
