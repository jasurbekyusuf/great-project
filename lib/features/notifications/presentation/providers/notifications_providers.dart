import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/config/env/app_env.dart';
import 'package:loadme_mobile/core/network/dio_client.dart';
import 'package:loadme_mobile/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:loadme_mobile/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:loadme_mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:loadme_mobile/features/notifications/domain/repositories/notifications_repository.dart';

// Re-export the entity so the screen needs only one import.
export 'package:loadme_mobile/features/notifications/domain/entities/app_notification.dart';

/// Notifications repository over the shared [dioProvider] (already pointed at
/// the active local/prod environment; the bearer token is auto-attached).
final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  return NotificationsRepositoryImpl(
    NotificationsRemoteDataSource(
      ref.watch(dioProvider),
      origin: ref.watch(appEnvProvider).origin,
    ),
  );
});

/// The "Xabarlar" list + read-state mutations.
final notificationsControllerProvider = AutoDisposeAsyncNotifierProvider<
    NotificationsController, List<AppNotification>>(
  NotificationsController.new,
);

/// Authoritative unread count from the dedicated endpoint
/// (`GET /notifications/unread-count/`). Drives the badge before the Xabarlar
/// list is ever opened and when the heavier list fetch fails. Returns 0 on
/// error (guests get a 401 → no badge).
final unreadNotificationsCountFetchProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final result = await ref.watch(notificationsRepositoryProvider).getUnreadCount();
  return result.fold((_) => 0, (count) => count);
});

/// Unread count for the bottom-nav "Xabarlar" badge. Prefers the loaded list so
/// optimistic mark-read updates the badge instantly; otherwise falls back to
/// the dedicated unread-count endpoint so the badge shows on app start even
/// when the list hasn't been opened (the previous list-only derivation read 0
/// until the Xabarlar screen had successfully loaded).
final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  final listState = ref.watch(notificationsControllerProvider);
  if (listState is AsyncData<List<AppNotification>>) {
    return listState.value.where((n) => !n.isRead).length;
  }
  return ref.watch(unreadNotificationsCountFetchProvider).maybeWhen(
        data: (count) => count,
        orElse: () => 0,
      );
});

class NotificationsController
    extends AutoDisposeAsyncNotifier<List<AppNotification>> {
  NotificationsRepository get _repo =>
      ref.read(notificationsRepositoryProvider);

  @override
  Future<List<AppNotification>> build() async {
    final result = await _repo.getNotifications();
    return result.fold((f) => throw f, (list) => list);
  }

  /// Re-fetch from REST (pull-to-refresh and error-retry).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.getNotifications();
      return result.fold((f) => throw f, (list) => list);
    });
  }

  /// Optimistically marks one notification read, then persists. A failed POST
  /// is swallowed — the next refresh reconciles the read state.
  Future<void> markRead(String id) async {
    final current = state.valueOrNull ?? const <AppNotification>[];
    final hit = current.where((n) => n.id == id);
    if (hit.isEmpty || hit.first.isRead) return;
    state = AsyncData([
      for (final n in current)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ]);
    await _repo.markRead(id);
  }

  /// Optimistically marks the whole list read, then persists.
  Future<void> markAllRead() async {
    final current = state.valueOrNull ?? const <AppNotification>[];
    if (current.isEmpty || current.every((n) => n.isRead)) return;
    state = AsyncData([for (final n in current) n.copyWith(isRead: true)]);
    await _repo.markAllRead();
  }
}
