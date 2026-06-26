import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/features/notifications/domain/entities/app_notification.dart';

/// In-app notifications ("Xabarlar"): the caller's list plus the read-state
/// mutations. Identity is the logged-in user's bearer token (attached by the
/// shared Dio interceptor); the list endpoint requires authentication.
abstract interface class NotificationsRepository {
  AsyncResult<List<AppNotification>> getNotifications();

  /// Marks a single user-notification read (`POST /notifications/{id}/read/`).
  AsyncResult<void> markRead(String id);

  /// Marks every notification read (`POST /notifications/read-all/`).
  AsyncResult<void> markAllRead();
}
