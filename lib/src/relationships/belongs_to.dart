part of yacht;

class BelongsTo<T extends DataModel<T>> {
  int? key;
  late final DataModel owner;
  late final String relName;
  String get prefix => '${owner._internalType}:${owner.yachtKey}';

  String get _internalType => T.toString();

  BelongsTo([T? model]) : this._(model?.yachtKey);
  BelongsTo._(this.key);

  void init(DataModel owner, String relName) {
    this.owner = owner;
    this.relName = relName;

    if (key != null) {
      final metas = Yacht._isar.collection<Meta>();
      metas.isar.writeTxnSync(
        () => metas.putSync(
          Meta(relId: '$prefix:$relName', value: key!),
        ),
      );
    }
  }

  T? get value {
    final metas = Yacht._isar.collection<Meta>();
    final key = metas
        .buildQuery<Meta>(whereClauses: [
          IndexWhereClause.between(
            indexName: r'relId',
            lower: [prefix],
            upper: ['$prefix\u{FFFFF}'],
          )
        ])
        .findFirstSync()
        ?.value;
    if (key != null) {
      return Yacht.repositories[_internalType]!.collection
          .queryByKey(key)
          .findFirstSync() as T?;
    } else {
      return null;
    }
  }

  set value(T? newValue) {
    key = newValue?.yachtKey;
    if (key != null) {
      final metas = Yacht._isar.collection<Meta>();
      metas.isar.writeTxnSync(
        () => metas.putSync(
          Meta(relId: '$prefix:$relName', value: key!),
        ),
      );
    }
  }
}
