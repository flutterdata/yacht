part of yacht;

/// Data request information holder.
///
/// Format examples:
///  - findAll/reports@b5d14c
///  - findOne/inspections#3@c4a1bb
///  - findAll/reports@b5d14c<c4a1bb
class DataRequestLabel with EquatableMixin {
  final String kind;
  final String type;
  final String? id;
  DataModel? model;
  final timestamp = DateTime.now();
  final _requestIds = <String>[];

  String get requestId => _requestIds.first;
  int get indentation => _requestIds.length - 1;

  DataRequestLabel(
    String kind, {
    required this.type,
    this.id,
    String? requestId,
    this.model,
    DataRequestLabel? withParent,
  }) : kind = kind.trim() {
    assert(!type.contains('#'));
    if (id != null) {
      assert(!id!.contains('#'));
    }
    if (requestId != null) {
      assert(!requestId.contains('@'));
    }
    _requestIds.add(requestId!); // ?? DataHelpers.generateShortKey()

    if (withParent != null) {
      _requestIds.addAll(withParent._requestIds);
    }
  }

  factory DataRequestLabel.parse(String text) {
    final parts = text.split('/');
    final parts2 = parts.last.split('@');
    final parts3 = parts2[0].split('#');
    final kind = (parts..removeLast()).join('/');
    final requestId = parts2[1];
    final type = parts3[0];
    final id = parts3.length > 1 ? parts3[1] : null;

    return DataRequestLabel(kind, type: type, id: id, requestId: requestId);
  }

  @override
  String toString() {
    return '$kind/$type:${(id ?? '')}@${_requestIds.join('<')}';
  }

  @override
  List<Object?> get props => [kind, type, id, _requestIds];
}

class DataResponse {
  final Object? body;
  final int statusCode;
  final Map<String, String> headers;

  const DataResponse(
      {this.body, required this.statusCode, this.headers = const {}});
}
