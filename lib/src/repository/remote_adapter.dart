part of yacht;

abstract class RemoteAdapter<T extends DataModel<T>> {
  final Repository<T> repository;
  RemoteAdapter({required this.repository});

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

    return repository
        .deserialize(jsonDecode(response.body) as Map<String, dynamic>);
  }
}

final yachtHttpClientProvider = Provider<http.Client>((_) => http.Client());
