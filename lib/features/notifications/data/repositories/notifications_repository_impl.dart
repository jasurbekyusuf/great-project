import 'package:loadme_mobile/core/result/guard.dart';
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:loadme_mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:loadme_mobile/features/notifications/domain/repositories/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._ds);

  final NotificationsRemoteDataSource _ds;
  static const _tag = 'NotificationsRepository';

  static AsyncResult<T> _guard<T>(Future<T> Function() block) =>
      Guard.run(block, tag: _tag);

  @override
  AsyncResult<List<AppNotification>> getNotifications() =>
      _guard(_ds.getNotifications);

  @override
  AsyncResult<int> getUnreadCount() => _guard(_ds.getUnreadCount);

  @override
  AsyncResult<void> markRead(String id) => _guard(() => _ds.markRead(id));

  @override
  AsyncResult<void> markAllRead() => _guard(_ds.markAllRead);
}
