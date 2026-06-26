import 'package:dio/dio.dart';

/// REST client for the "Fikr bildirish" support-ticket form.
///
/// `POST /feedback/support-tickets/` — multipart with `title`, `comment` and
/// optional `files`. Identity is the logged-in user's bearer token (attached
/// by the shared Dio interceptor).
class SupportFeedbackRemoteDataSource {
  SupportFeedbackRemoteDataSource(this._dio);

  final Dio _dio;

  Future<void> createTicket({
    required String title,
    required String comment,
    List<MultipartFile> files = const [],
  }) async {
    final form = FormData();
    form.fields
      ..add(MapEntry('title', title))
      ..add(MapEntry('comment', comment));
    for (final f in files) {
      form.files.add(MapEntry('files', f));
    }
    await _dio.post<dynamic>('/feedback/support-tickets/', data: form);
  }
}
