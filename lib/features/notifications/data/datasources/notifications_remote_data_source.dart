import 'package:dio/dio.dart';
import 'package:loadme_mobile/features/notifications/domain/entities/app_notification.dart';

/// Dio-backed client for the user notifications endpoints.
///
/// Same `{ success, data }` envelope and `{ results, ... }` pagination as the
/// rest of the API. The list is short (the backend caps what a user accrues),
/// so one large page is fetched instead of paginating, then sorted
/// newest-first for the grouped "Bugun / Bu hafta" view.
class NotificationsRemoteDataSource {
  NotificationsRemoteDataSource(this._dio, {required this.origin});

  final Dio _dio;

  /// Scheme+host used to absolutise relative `/media/...` hero image URLs.
  final String origin;

  static const _pageSize = 50;

  Future<List<AppNotification>> getNotifications() async {
    final res = await _dio.get<dynamic>(
      '/notifications/',
      queryParameters: {'page': 1, 'page_size': _pageSize},
    );
    return _resultsOf(res)
        .map((m) => AppNotification.fromJson(m, origin: origin))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Authoritative unread count for the bottom-nav badge
  /// (`GET /notifications/unread-count/`) — independent of the heavier list
  /// fetch, so the badge shows even before the Xabarlar screen is opened.
  Future<int> getUnreadCount() async {
    final res = await _dio.get<dynamic>('/notifications/unread-count/');
    final data = _peel(res.data);
    if (data is num) return data.toInt();
    if (data is Map) {
      final v = data['count'] ??
          data['unread_count'] ??
          data['unread'] ??
          data['total'];
      if (v is num) return v.toInt();
      return int.tryParse('${v ?? ''}') ?? 0;
    }
    return int.tryParse('$data') ?? 0;
  }

  Future<void> markRead(String id) async {
    await _dio.post<dynamic>('/notifications/$id/read/');
  }

  Future<void> markAllRead() async {
    await _dio.post<dynamic>('/notifications/read-all/');
  }

  // --- envelope helpers ------------------------------------------------------

  List<Map<String, dynamic>> _resultsOf(Response<dynamic> res) {
    final inner = _peel(res.data);
    final list = inner is List
        ? inner
        : (inner is Map ? (inner['results'] ?? inner['result']) : null);
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Peels the `{ success, data }` envelope when present.
  dynamic _peel(dynamic body) {
    if (body is Map && body.containsKey('data') && body['data'] != null) {
      return body['data'];
    }
    return body;
  }
}
