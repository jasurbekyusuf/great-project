import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/storage/providers.dart';

// Async role lookup (one-shot).
final currentUserRoleProvider = FutureProvider<String>((ref) async {
  final data = await ref.watch(storageProvider).readJson('user_data');
  final roles = data?['role'];
  if (roles is List && roles.isNotEmpty) {
    final first = roles.first.toString().toLowerCase();
    if (first == 'carrier' || first == 'broker' || first == 'shipper') return first;
  }
  return 'shipper';
});

// Synchronous role state used by widgets that can't await. Hydrated by
// `CurrentUserRoleController` from storage on first read; updated by the auth
// flow whenever a fresh `user_data` blob is persisted.
class CurrentUserRoleController extends Notifier<String> {
  @override
  String build() {
    // Kick off async hydration; default to shipper until it lands.
    ref.read(storageProvider).readJson('user_data').then((data) {
      final roles = data?['role'];
      if (roles is List && roles.isNotEmpty) {
        final first = roles.first.toString().toLowerCase();
        if (first == 'carrier' || first == 'broker' || first == 'shipper') {
          state = first;
        }
      }
    });
    return 'shipper';
  }

  void setRole(String role) {
    final normalized = role.toLowerCase();
    if (normalized == 'carrier' || normalized == 'broker' || normalized == 'shipper') {
      state = normalized;
    }
  }
}

final currentUserRoleSyncProvider =
    NotifierProvider<CurrentUserRoleController, String>(CurrentUserRoleController.new);
