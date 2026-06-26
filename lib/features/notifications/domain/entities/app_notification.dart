/// Domain model for an in-app notification (the "Xabarlar" list).
///
/// The backend serves user-notifications under `GET /notifications/`: each row
/// joins the per-user read state (`is_read`, plus the row `id` consumed by
/// `POST /notifications/{id}/read/`) with a multilingual notification
/// (`title_uz|ru|uz_cyrl`, `body_*`, `type`). The server localizes by
/// `Accept-Language`, so a resolved `title`/`body` is preferred and the
/// per-language fields are a tolerant fallback. The payload is parsed
/// defensively (flat OR nested under `notification`) so the UI never touches
/// raw JSON.
library;

/// Coarse kind that drives the card icon (and the optional "Ko'rish" button):
/// load-related alerts get the package icon, everything else the bell.
enum NotificationKind { load, system }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.kind,
    this.imageUrl,
  });

  /// User-notification id — the cursor for `POST /notifications/{id}/read/`.
  final String id;
  final String title;
  final String body;

  /// Raw backend type (`announcement`, `personal`, `everyone`, `guests`,
  /// `driver`, …) — kept for analytics / future deep-linking.
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final NotificationKind kind;

  /// Optional hero image for the detail screen (relative `/media/...` paths are
  /// absolutised against the active origin when parsed).
  final String? imageUrl;

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        body: body,
        type: type,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        kind: kind,
        imageUrl: imageUrl,
      );

  static AppNotification fromJson(
    Map<String, dynamic> json, {
    String origin = '',
  }) {
    // A user-notification row may nest the content under `notification`.
    final n = json['notification'] is Map
        ? (json['notification'] as Map).cast<String, dynamic>()
        : json;

    // Picks the first non-empty value across the resolved key then its
    // per-language variants, looking in both the row and the nested object.
    String pick(List<String> bases) {
      for (final b in bases) {
        final v = json[b] ??
            n[b] ??
            n['${b}_uz'] ??
            n['${b}_uz_cyrl'] ??
            n['${b}_ru'];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString();
      }
      return '';
    }

    final type = (n['type'] ?? json['type'] ?? '').toString();

    final dataRaw = json['data'] ?? n['data'];
    final data = dataRaw is Map ? dataRaw : const <dynamic, dynamic>{};
    final loadId =
        (data['load'] ?? data['load_id'] ?? data['object_id'] ?? '').toString();

    final rawImage =
        (n['image'] ?? n['image_url'] ?? n['hero'] ?? json['image'] ?? '')
            .toString();
    final image =
        rawImage.isEmpty || rawImage.startsWith('http') || origin.isEmpty
            ? rawImage
            : '$origin$rawImage';

    final lower = type.toLowerCase();
    final isLoad = lower.contains('load') ||
        lower.contains('driver') ||
        lower.contains('route') ||
        loadId.isNotEmpty;

    return AppNotification(
      id: (json['id'] ?? n['id'] ?? '').toString(),
      title: pick(['title']),
      body: pick(['body', 'message', 'text', 'description']),
      type: type,
      isRead: json['is_read'] == true || n['is_read'] == true,
      createdAt: DateTime.tryParse(
                (json['created_at'] ?? n['created_at'] ?? '').toString(),
              )?.toLocal() ??
          DateTime.now(),
      kind: isLoad ? NotificationKind.load : NotificationKind.system,
      imageUrl: image.isEmpty ? null : image,
    );
  }
}
