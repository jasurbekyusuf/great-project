import 'dart:convert';

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

const _knownRoles = {'carrier', 'broker', 'shipper'};

String? _roleFromUserData(String? raw) {
  if (raw == null) return null;
  try {
    final data = jsonDecode(raw);
    final roles = data is Map ? data['role'] : null;
    if (roles is List && roles.isNotEmpty) {
      final first = roles.first.toString().toLowerCase();
      if (_knownRoles.contains(first)) return first;
    }
  } catch (_) {
    // Corrupt/legacy blob — caller falls back to the default role.
  }
  return null;
}

// Synchronous role state used by widgets (and the router redirect) that can't
// await. Hydrated *synchronously* from the cached `user_data` blob on first
// read so a cold start lands the user on their correct role home; updated by
// the auth flow whenever a fresh `user_data` blob is persisted.
class CurrentUserRoleController extends Notifier<String> {
  @override
  String build() {
    // SharedPreferences getters are synchronous, so the persisted role is
    // available on the very first read — no async gap for the redirect to race.
    final raw = ref.read(sharedPreferencesProvider).getString('user_data');
    return _roleFromUserData(raw) ?? 'shipper';
  }

  void setRole(String role) {
    final normalized = role.toLowerCase();
    if (_knownRoles.contains(normalized)) {
      state = normalized;
    }
  }
}

final currentUserRoleSyncProvider =
    NotifierProvider<CurrentUserRoleController, String>(CurrentUserRoleController.new);
