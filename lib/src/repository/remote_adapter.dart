part of yacht;

mixin _RemoteAdapter<T extends DataModel<T>> on _SerializationAdapter<T> {
  @protected
  String get baseUrl => 'https://override-base-url-in-adapter/';

  @protected
  @visibleForTesting
  http.Client get httpClient => http.Client();

  @protected
  FutureOr<Map<String, dynamic>> get defaultParams => {};

  @protected
  FutureOr<Map<String, String>> get defaultHeaders =>
      {'Content-Type': 'application/json'};

  Object? _resolveId(Object obj) {
    return obj is T ? obj.id : obj;
  }

  Future<T?> asyncFindOne(
    Object id, {
    bool remote = true,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
  }) async {
    params = await defaultParams & params;
    headers = await defaultHeaders & headers;

    final resolvedId = _resolveId(id);

    if (remote == false) {
      return findOne(id);
    }

    final response =
        await httpClient.get(Uri.parse(baseUrl) / resolvedId.toString());

    return deserialize(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
