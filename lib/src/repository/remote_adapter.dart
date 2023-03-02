part of yacht;

class _RemoteAdapter<T extends DataModel<T>> {
  final Repository<T> repository;
  _RemoteAdapter({required this.repository});

  @protected
  String get baseUrl => 'https://override-base-url-in-adapter/';

  @protected
  @visibleForTesting
  http.Client get httpClient => repository.ref.read(yachtHttpClientProvider);

  @protected
  FutureOr<Map<String, dynamic>> get defaultParams => {};

  @protected
  FutureOr<Map<String, String>> get defaultHeaders =>
      {'Content-Type': 'application/json'};

  Object? _resolveId(Object obj) {
    return obj is T ? obj.id : obj;
  }

  Future<T?> findOne(
    Object id, {
    bool remote = true,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
  }) async {
    params = await defaultParams & params;
    headers = await defaultHeaders & headers;

    final resolvedId = _resolveId(id);

    if (remote == false) {
      return repository.findOne(id);
    }

    final response =
        await httpClient.get(Uri.parse(baseUrl) / resolvedId.toString());
    final deserialized = await deserialize(response.body);
    return deserialized.model;
  }

  Future<DeserializedData<T>> deserialize(Object? data) async {
    final result = DeserializedData<T>([], included: []);

    //   Future<Object?> _processIdAndAddInclude(id, Repository? adapter) async {
    //     if (id is Map && adapter != null) {
    //       final data = await adapter.deserialize(id as Map<String, dynamic>);
    //       result.included
    //         ..add(data.model as DataModel<DataModel>)
    //         ..addAll(data.included);
    //       id = data.model!.id;
    //     }
    //     if (id != null && adapter != null) {
    //       // TODO restore
    //       // return graph.getKeyForId(adapter.internalType, id,
    //       //     keyIfAbsent: DataHelpers.generateKey(adapter.internalType));
    //     }
    //     return null;
    //   }

    //   if (data == null || data == '') {
    //     return result;
    //   }

    //   if (data is Map<String, dynamic>) {
    //     data = [data];
    //   }

    //   if (data is Iterable) {
    //     for (final map in data) {
    //       final mapIn = Map<String, dynamic>.from(map as Map);
    //       final mapOut = <String, dynamic>{};

    //       final relationships = localAdapter.relationshipMetas;

    //       // - process includes
    //       // - transform ids into keys to pass to the local deserializer
    //       for (final mapKey in mapIn.keys) {
    //         final metadata = relationships[mapKey];

    //         if (metadata != null) {
    //           final relType = metadata.type;

    //           if (metadata.serialize == false) {
    //             continue;
    //           }

    //           // if (metadata.kind == 'BelongsTo') {
    //           //   final key = await _processIdAndAddInclude(
    //           //       mapIn[mapKey], adapters[relType]!);
    //           //   if (key != null) mapOut[mapKey] = key;
    //           // }

    //           // if (metadata.kind == 'HasMany') {
    //           //   mapOut[mapKey] = [
    //           //     for (final id in (mapIn[mapKey] as Iterable))
    //           //       await _processIdAndAddInclude(id, adapters[relType]!)
    //           //   ].withoutNulls;
    //           // }
    //         } else {
    //           // regular field mapping
    //           mapOut[mapKey] = mapIn[mapKey];
    //         }
    //       }

    //       final model = localAdapter.deserialize(mapOut);
    //       result.models.add(model);
    //     }
    //   }

    return result;
  }
}

final yachtHttpClientProvider = Provider<http.Client>((_) => http.Client());
