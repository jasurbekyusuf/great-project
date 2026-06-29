import 'package:dio/dio.dart';
import 'package:loadme_mobile/features/support/domain/entities/support_message.dart';

/// REST client for the user/guest support chat (`/feedback/support/chat/`).
///
/// REST is the **source of truth**: sending, history and read all go here.
/// Identity is one of:
///   * `Authorization: Bearer <token>` — attached automatically by the shared
///     Dio interceptor when the user is logged in;
///   * `X-Guest-Id: <device-uuid>` — passed here for guests (and, harmlessly,
///     for logged-in users too: the backend merges the guest conversation on
///     the first request, which is idempotent).
///
/// The standard envelope is `{ success, data }`; history is paginated
/// `{ results, count, next, previous }` oldest→newest, 30/page.
class SupportChatRemoteDataSource {
  SupportChatRemoteDataSource(this._dio, {required this.origin});

  final Dio _dio;

  /// Scheme+host used to absolutise relative `/media/...` file URLs.
  final String origin;

  static const _base = '/feedback/support/chat';

  /// Safety cap so a runaway history never pages forever (support threads are
  /// short; 10×30 = 300 messages is plenty for the in-memory view).
  static const _maxHistoryPages = 10;

  Options _opts(String? guestId) => Options(
        headers: (guestId != null && guestId.isNotEmpty)
            ? {'X-Guest-Id': guestId}
            : null,
      );

  /// Conversation meta (creates the conversation if missing).
  Future<SupportConversationMeta> getConversation({String? guestId}) async {
    final res = await _dio.get<dynamic>('$_base/', options: _opts(guestId));
    return SupportConversationMeta.fromJson(_object(res.data));
  }

  /// Full history, oldest→newest, following pagination so the newest message
  /// is always included (the cursor for subsequent delta polls).
  Future<List<SupportMessage>> getHistory({String? guestId}) async {
    final all = <SupportMessage>[];
    for (var page = 1; page <= _maxHistoryPages; page++) {
      final res = await _dio.get<dynamic>(
        '$_base/messages/',
        queryParameters: {'page': page},
        options: _opts(guestId),
      );
      final data = _unwrap(res.data);
      all.addAll(_parseList(data));
      final hasNext = data is Map && data['next'] != null;
      if (!hasNext) break;
    }
    return all;
  }

  /// Delta poll — only messages strictly after [afterId] (UUIDv7 cursor).
  Future<List<SupportMessage>> getMessagesAfter(
    String afterId, {
    String? guestId,
  }) async {
    final res = await _dio.get<dynamic>(
      '$_base/messages/',
      queryParameters: {'after_id': afterId},
      options: _opts(guestId),
    );
    return _parseList(_unwrap(res.data));
  }

  /// Send a message (text and/or files). At least one is required by the
  /// backend; the caller guarantees that.
  Future<SupportMessage> sendMessage({
    String? text,
    List<MultipartFile> files = const [],
    String? guestId,
  }) async {
    final form = FormData();
    final trimmed = text?.trim() ?? '';
    if (trimmed.isNotEmpty) form.fields.add(MapEntry('text', trimmed));
    for (final f in files) {
      form.files.add(MapEntry('files', f));
    }
    final res = await _dio.post<dynamic>(
      '$_base/messages/',
      data: form,
      options: _opts(guestId),
    );
    return SupportMessage.fromJson(_object(res.data), origin: origin);
  }

  /// Preset FAQ buttons (`{ id, question }`), already localized and in display
  /// order. The answer is delivered only on [askFaq]. Auth not required (the
  /// identity header is still sent so the exchange lands in this conversation).
  Future<List<SupportFaq>> getFaqs({String? guestId}) async {
    final res = await _dio.get<dynamic>('$_base/faqs/', options: _opts(guestId));
    final data = _unwrap(res.data);
    final raw = data is List ? data : const [];
    return raw
        .whereType<Map>()
        .map((m) => SupportFaq.fromJson(m.cast<String, dynamic>()))
        .toList();
  }

  /// Tap an FAQ → the backend records BOTH the question and the automated
  /// answer in this conversation and returns the two messages (question first,
  /// then the `is_automated: true` answer). Self-service: no operator is pinged
  /// and no push is sent. The two messages have real ids, so they de-dupe
  /// cleanly against the poll / WebSocket.
  Future<List<SupportMessage>> askFaq(String faqId, {String? guestId}) async {
    final res = await _dio.post<dynamic>(
      '$_base/faqs/$faqId/ask/',
      options: _opts(guestId),
    );
    return _parseList(_unwrap(res.data));
  }

  /// Mark the whole conversation read (call when the chat is opened and after
  /// staff messages arrive). Resets `user_unread_count` to 0.
  Future<void> markRead({String? guestId}) =>
      _dio.post<dynamic>('$_base/read/', options: _opts(guestId));

  /// Unread message count for the badge.
  Future<int> getUnreadCount({String? guestId}) async {
    final res =
        await _dio.get<dynamic>('$_base/unread-count/', options: _opts(guestId));
    return (_object(res.data)['unread_count'] as num?)?.toInt() ?? 0;
  }

  // --- envelope helpers ------------------------------------------------------

  /// Strips the `{ success, data }` envelope, returning the inner payload
  /// (which may be a Map for objects or a List for bare arrays).
  Object? _unwrap(Object? body) {
    if (body is Map && body.containsKey('data')) return body['data'];
    return body;
  }

  Map<String, dynamic> _object(Object? body) {
    final inner = _unwrap(body);
    if (inner is Map) return inner.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  List<SupportMessage> _parseList(Object? data) {
    final List raw;
    if (data is Map && data['results'] is List) {
      raw = data['results'] as List;
    } else if (data is List) {
      raw = data;
    } else {
      raw = const [];
    }
    return raw
        .whereType<Map>()
        .map((m) => SupportMessage.fromJson(m.cast<String, dynamic>(), origin: origin))
        .toList();
  }
}
