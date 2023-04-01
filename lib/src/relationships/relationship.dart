part of yacht;

abstract class Relationship<T extends DataModel<T>> {
  String get _internalType => T.toString();
  String get _relId => '${_owner!._internalType}:${_owner!.yachtKey}:$_name';
  final _metas = Yacht._isar.collection<Meta>();

  Set<int> _uninitializedKeys;
  DataModel? _owner;
  String? _name;
  // ignore: unused_field
  String? _inverseName;

  Relationship._(this._uninitializedKeys);

  void _init(
      {required DataModel owner, required String name, String? inverseName}) {
    this._owner = owner;
    this._name = name;
    this._inverseName = inverseName;

    if (_uninitializedKeys.isNotEmpty) {
      _saveMetaWith({..._keys, ..._uninitializedKeys});
    }
  }

  List<int> get _keys {
    return _metas
            .buildQuery<Meta>(whereClauses: [
              IndexWhereClause.equalTo(indexName: r'relId', value: [_relId])
            ])
            .findFirstSync()
            ?.value ??
        [];
  }

  void _saveMetaWith(Set<int> keys) {
    _metas.isar.writeTxnSync(
      () => _metas.putSync(
        Meta(relId: _relId, value: keys.toList()),
      ),
    );
  }
}

// meta

class DataRelationship {
  final String? inverse;
  const DataRelationship({this.inverse});
}

class RelationshipGraphNode<T extends DataModel<T>> {}

class RelationshipMeta<T extends DataModel<T>>
    with RelationshipGraphNode<T>, EquatableMixin {
  final String name;
  final String? inverseName;
  final String type;
  final Relationship? Function(DataModel) instance;
  RelationshipMeta? parent;
  RelationshipMeta? child;

  RelationshipMeta({
    required this.name,
    this.inverseName,
    required this.type,
    required this.instance,
  });

  RelationshipMeta<T> clone({RelationshipMeta? parent}) {
    final meta = RelationshipMeta<T>(
      name: name,
      type: type,
      instance: instance,
    );
    if (parent != null) {
      meta.parent = parent;
      meta.parent!.child = meta; // automatically set child
    }
    return meta;
  }

  @override
  List<Object?> get props => [name, inverseName, type];
}
