part of yacht;

class HasMany<T extends DataModel<T>> extends Relationship<T> {
  HasMany([Set<T>? models])
      : this._(models?.map((e) => e.yachtKey).toSet() ?? {});
  HasMany._(Set<int> key) : super._(key);

  void _init(
      {required DataModel owner, required String name, String? inverseName}) {
    super._init(owner: owner, name: name, inverseName: inverseName);
  }

  add(T value) {
    value.save();
    _saveMetaWith({..._keys, value.yachtKey});
  }

  remove(T value) {
    _saveMetaWith(_keys.where((e) => e != value.yachtKey).toSet());
  }

  Set<T> toSet() {
    if (_keys.isEmpty) {
      return {};
    }

    return Yacht.repositories[_internalType]!.collection
        .where()
        .anyOf(_keys, (qb, int key) {
          // ignore: invalid_use_of_protected_member
          return QueryBuilder.apply(qb, (query) {
            return query.addWhereClause(IdWhereClause.between(
              lower: key,
              upper: key,
            ));
          });
        })
        .findAllSync()
        .cast<T>()
        .toSet();
  }
}
