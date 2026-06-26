/// Domain models for the real-time support chat.
///
/// REST is the source of truth (history, send, read); the WebSocket only
/// pushes a lighter live payload. These models parse BOTH shapes tolerantly:
///   REST msg : { id, text, is_from_staff, is_read, sender:{is_staff,
///               display_name}, files:[{id,file,original_name,created_at}],
///               created_at }
///   WS   msg : { id, conversation_id, text, is_from_staff, created_at,
///               files:[{original_name, file}] }
library;

/// A single file attached to a support message.
class SupportFile {
  const SupportFile({
    required this.url,
    required this.originalName,
    this.id,
  });

  final String? id;

  /// Absolute URL (relative `/media/...` paths are absolutised against the
  /// active origin when parsed).
  final String url;
  final String originalName;

  static SupportFile fromJson(Map<String, dynamic> json, {String origin = ''}) {
    final raw = (json['file'] ?? json['url'] ?? '').toString();
    final abs = raw.startsWith('http') || raw.isEmpty || origin.isEmpty
        ? raw
        : '$origin$raw';
    return SupportFile(
      id: json['id']?.toString(),
      url: abs,
      originalName: (json['original_name'] ?? json['name'] ?? '').toString(),
    );
  }
}

/// One chat message — from the user/guest or from a support agent.
class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.text,
    required this.isFromStaff,
    required this.createdAt,
    this.isRead = false,
    this.senderName = '',
    this.files = const [],
    this.pending = false,
  });

  final String id;
  final String text;
  final bool isFromStaff;
  final bool isRead;

  /// Masked display name — `Support` for staff, `You` for the owner. The
  /// agent's real name/phone is never exposed by the backend.
  final String senderName;
  final List<SupportFile> files;
  final DateTime createdAt;

  /// `true` for an optimistic local bubble awaiting the POST response.
  final bool pending;

  /// Client-only optimistic id prefix so temp bubbles never clash with the
  /// backend's UUIDv7 ids.
  bool get isTemp => id.startsWith('local-');

  static SupportMessage fromJson(Map<String, dynamic> json, {String origin = ''}) {
    final sender = json['sender'];
    final senderName = sender is Map
        ? (sender['display_name']?.toString() ?? '')
        : '';
    final isStaff = json['is_from_staff'] == true ||
        (sender is Map && sender['is_staff'] == true);
    final filesRaw = json['files'];
    final files = filesRaw is List
        ? filesRaw
            .whereType<Map>()
            .map((f) => SupportFile.fromJson(f.cast<String, dynamic>(), origin: origin))
            .toList()
        : const <SupportFile>[];
    return SupportMessage(
      id: json['id']?.toString() ?? '',
      text: (json['text'] ?? '').toString(),
      isFromStaff: isStaff,
      isRead: json['is_read'] == true,
      senderName: senderName.isNotEmpty
          ? senderName
          : (isStaff ? 'Support' : 'You'),
      files: files,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
    );
  }

  /// Optimistic local echo shown the instant the user taps send.
  factory SupportMessage.optimistic(String text) => SupportMessage(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        text: text,
        isFromStaff: false,
        senderName: 'You',
        createdAt: DateTime.now(),
        pending: true,
      );
}

/// Conversation meta — drives the unread badge and "last message" preview.
class SupportConversationMeta {
  const SupportConversationMeta({
    required this.id,
    required this.status,
    required this.userUnreadCount,
    this.lastMessagePreview = '',
    this.lastMessageIsFromStaff = false,
    this.lastMessageAt,
  });

  final String id;
  final String status;
  final int userUnreadCount;
  final String lastMessagePreview;
  final bool lastMessageIsFromStaff;
  final DateTime? lastMessageAt;

  static SupportConversationMeta fromJson(Map<String, dynamic> json) {
    return SupportConversationMeta(
      id: json['id']?.toString() ?? '',
      status: (json['status'] ?? 'open').toString(),
      userUnreadCount: (json['user_unread_count'] as num?)?.toInt() ?? 0,
      lastMessagePreview: (json['last_message_preview'] ?? '').toString(),
      lastMessageIsFromStaff: json['last_message_is_from_staff'] == true,
      lastMessageAt:
          DateTime.tryParse(json['last_message_at']?.toString() ?? '')?.toLocal(),
    );
  }
}
