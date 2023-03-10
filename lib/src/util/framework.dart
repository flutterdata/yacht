part of yacht;

class Yacht {
  static late Isar _isar;
  static late Map<String, Repository> repositories;

  static final initialize =
      FutureProvider.family<void, List<Provider<Repository>>>(
          (ref, repositoryProviders) async {
    if (Isar.getInstance('yacht') != null) {
      return;
    }

    final _repositories = repositoryProviders.map(ref.read);
    final schemas = _repositories.map((r) => r._schema).toList();

    repositories = {
      for (final repository in _repositories)
        repository.internalType: repository,
    };

    _isar = await Isar.open(schemas, name: 'yacht', inspector: false);
  });

  static void clear() {
    _isar.writeTxnSync(() => _isar.clearSync());
  }

  static Future<void> dispose({bool destroy = false}) async {
    await _isar.close(deleteFromDisk: destroy);
    repositories.clear();
  }
}

// extensions

extension StringUtilsX on String {
  String capitalize() =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';

  String decapitalize() =>
      isEmpty ? '' : '${this[0].toLowerCase()}${substring(1)}';

  String pluralize() => inflection.pluralize(this);
}

extension IterableNullX<T> on Iterable<T?> {
  @protected
  @visibleForTesting
  Iterable<T> get withoutNulls => where((elem) => elem != null).cast();
}

extension MapUtilsX<K, V> on Map<K, V> {
  @protected
  @visibleForTesting
  Map<K, V> operator &(Map<K, V>? more) => {...this, ...?more};
}

extension UriUtilsX on Uri {
  Uri operator /(String path) {
    return replace(path: path_helper.posix.normalize('/${this.path}/$path'));
  }

  Uri operator &(Map<String, dynamic> params) => params.isNotEmpty
      ? replace(
          queryParameters: queryParameters & _flattenQueryParameters(params))
      : this;
}

Map<String, String> _flattenQueryParameters(Map<String, dynamic> params) {
  return params.entries.fold<Map<String, String>>({}, (acc, e) {
    if (e.value is Map<String, dynamic>) {
      for (final e2 in (e.value as Map<String, dynamic>).entries) {
        acc['${e.key}[${e2.key}]'] = e2.value.toString();
      }
    } else {
      acc[e.key] = e.value.toString();
    }
    return acc;
  });
}
