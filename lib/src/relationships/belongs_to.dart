part of yacht;

class BelongsTo<T extends DataModel<T>> extends Relationship<T> {
  BelongsTo([T? model]) : this._(model?.yachtKey);
  BelongsTo._(int? key) : super._({key}.withoutNulls.toSet());

  void _init(
      {required DataModel owner, required String name, String? inverseName}) {
    super._init(owner: owner, name: name, inverseName: inverseName);
  }

  remove(T value) {
    _saveMetaWith(_keys.where((e) => e != value.yachtKey).toSet());
  }

  T? get value {
    if (_keys.isNotEmpty) {
      return Yacht.repositories[_internalType]!.collection
          .queryByKey(_keys.first)
          .findFirstSync() as T?;
    } else {
      return null;
    }
  }

  set value(T? newValue) {
    if (newValue != null) {
      newValue.save();
      _saveMetaWith({newValue.yachtKey});
    } else {
      _saveMetaWith({});
    }
  }
}
