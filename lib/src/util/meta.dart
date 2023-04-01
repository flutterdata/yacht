part of yacht;

class Meta {
  final Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  final String relId;

  final List<int> value;

  Meta({required this.relId, required this.value});

  @override
  String toString() {
    return '<Meta>{relId: $relId, value: [${value.join(', ')}]}';
  }
}

const metaSchema = CollectionSchema(
  name: r'Meta',
  id: 3011675413520335034,
  properties: {
    r'relId': PropertySchema(
      id: 0,
      name: r'relId',
      type: IsarType.string,
    ),
    r'value': PropertySchema(
      id: 1,
      name: r'value',
      type: IsarType.longList,
    )
  },
  estimateSize: _metaEstimateSize,
  serialize: _metaSerialize,
  deserialize: _metaDeserialize,
  deserializeProp: _metaDeserializeProp,
  idName: r'id',
  indexes: {
    r'relId': IndexSchema(
      id: 9041799437181632716,
      name: r'relId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'relId',
          type: IndexType.value,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _metaGetId,
  getLinks: _metaGetLinks,
  attach: _metaAttach,
  version: '3.0.5',
);

int _metaEstimateSize(
  Meta object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.relId.length * 3;
  bytesCount += 3 + object.value.length * 8;
  return bytesCount;
}

void _metaSerialize(
  Meta object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.relId);
  writer.writeLongList(offsets[1], object.value);
}

Meta _metaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Meta(
    relId: reader.readString(offsets[0]),
    value: reader.readLongList(offsets[1]) ?? [],
  );
  return object;
}

P _metaDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLongList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _metaGetId(Meta object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _metaGetLinks(Meta object) {
  return [];
}

void _metaAttach(IsarCollection<dynamic> col, Id id, Meta object) {}
