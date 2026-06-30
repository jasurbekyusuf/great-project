import 'package:dio/dio.dart';

/// One selectable complaint reason from `GET /feedback/complaint-types/`
/// (localised server-side by `Accept-Language`).
class ComplaintType {
  const ComplaintType({required this.id, required this.name});
  final String id;
  final String name;
}

/// REST client for the rating / complaint feedback flow surfaced from the
/// owner / carrier card after the viewer has contacted them.
///
/// * `GET  /feedback/complaint-types/` — the reason list for the report sheet
/// * `POST /feedback/complaints/`      — `{to_user, load|route, complaint_type, note}`
/// * `POST /feedback/ratings/`         — `{to_user, truck_route?, rate, notes}`
///
/// Identity is the logged-in user's bearer token (attached by the shared Dio
/// interceptor); the response envelope is `{ success, data }`.
class FeedbackRemoteDataSource {
  FeedbackRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<ComplaintType>> getComplaintTypes() async {
    final res = await _dio.get<dynamic>('/feedback/complaint-types/');
    return _listOf(res.data).map((m) {
      return ComplaintType(
        id: (m['id'] ?? m['guid'] ?? '').toString(),
        name: (m['name'] ?? m['title'] ?? m['label'] ?? '').toString(),
      );
    }).where((t) => t.id.isNotEmpty && t.name.isNotEmpty).toList();
  }

  /// Files a complaint about [toUser]. The target is the [load] OR the [route]
  /// it was opened from (the backend accepts one, not both).
  Future<void> submitComplaint({
    required String toUser,
    required String complaintType,
    String? load,
    String? route,
    String? note,
  }) async {
    await _dio.post<dynamic>('/feedback/complaints/', data: <String, dynamic>{
      'to_user': toUser,
      'complaint_type': complaintType,
      if (load != null) 'load': load,
      if (route != null) 'route': route,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
  }

  /// Rates [toUser] (1–5). [truckRoute] scopes the rating to a specific route
  /// when one is available (the transport detail); a load owner is rated
  /// without it.
  Future<void> submitRating({
    required String toUser,
    required int rate,
    String? truckRoute,
    String? notes,
  }) async {
    await _dio.post<dynamic>('/feedback/ratings/', data: <String, dynamic>{
      'to_user': toUser,
      'rate': rate,
      if (truckRoute != null) 'truck_route': truckRoute,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    });
  }

  /// Peels the `{ success, data }` envelope and the optional `results` page,
  /// returning a list of string-keyed maps.
  List<Map<String, dynamic>> _listOf(dynamic body) {
    var inner = body;
    if (inner is Map && inner.containsKey('data') && inner['data'] != null) {
      inner = inner['data'];
    }
    if (inner is Map) inner = inner['results'] ?? inner['result'] ?? inner;
    if (inner is! List) return const [];
    return inner
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
