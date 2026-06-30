import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadme_mobile/config/routes/app_router.dart';
import 'package:loadme_mobile/core/storage/providers.dart';
import 'package:loadme_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:loadme_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:loadme_mobile/features/auth/presentation/providers/current_user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The real AuthController.build() restores the cached session from encrypted
// storage — an asynchronous read. That single async hop is exactly what made
// the cold-start redirect race: the router read the controller while it was
// still AsyncLoading. This fake keeps the async shape (one microtask hop) but
// skips secure storage, so we can prove main()'s pre-warm closes the gap.
class _RestoringAuth extends AuthController {
  @override
  Future<AuthSession?> build() async {
    await Future<void>.delayed(Duration.zero);
    return const AuthSession(token: 'cached-token');
  }
}

Future<SharedPreferences> _prefsWithRole(String? role) async {
  SharedPreferences.setMockInitialValues(
    role == null
        ? <String, Object>{}
        : <String, Object>{
            'user_data': jsonEncode({
              'role': [role],
            }),
          },
  );
  return SharedPreferences.getInstance();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('cold-start role hydration', () {
    test('reads the cached role on the very first synchronous read', () async {
      final prefs = await _prefsWithRole('carrier');
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      // No await, no pump: the first read must already be 'carrier'. If it were
      // still the 'shipper' default, the redirect would land a carrier on
      // /trucks instead of /loads on every cold start.
      expect(container.read(currentUserRoleSyncProvider), 'carrier');
    });

    test('falls back to shipper when no user_data is cached', () async {
      final prefs = await _prefsWithRole(null);
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(currentUserRoleSyncProvider), 'shipper');
    });
  });

  group('resolveStartupRedirect (auth gate)', () {
    test('logged-out user is pushed to /guest from a protected screen', () {
      expect(
        resolveStartupRedirect(
            isAuthed: false, location: '/loads', role: 'shipper'),
        '/guest',
      );
    });

    test('logged-out user is left alone on guest/auth screens', () {
      expect(
        resolveStartupRedirect(
            isAuthed: false, location: '/guest', role: 'shipper'),
        isNull,
      );
      expect(
        resolveStartupRedirect(
            isAuthed: false, location: '/auth/welcome', role: 'shipper'),
        isNull,
      );
    });

    test('a restored carrier session lands on /loads (the reported bug)', () {
      // Cold start: initialLocation is /guest, session restored, role carrier.
      expect(
        resolveStartupRedirect(
            isAuthed: true, location: '/guest', role: 'carrier'),
        '/loads',
      );
    });

    test('a restored shipper/broker session lands on /trucks', () {
      expect(
        resolveStartupRedirect(
            isAuthed: true, location: '/guest', role: 'shipper'),
        '/trucks',
      );
      expect(
        resolveStartupRedirect(
            isAuthed: true, location: '/guest', role: 'broker'),
        '/trucks',
      );
    });

    test('an authed user already on their home is left alone (no loop)', () {
      expect(
        resolveStartupRedirect(
            isAuthed: true, location: '/loads', role: 'carrier'),
        isNull,
      );
      expect(
        resolveStartupRedirect(
            isAuthed: true, location: '/trucks', role: 'shipper'),
        isNull,
      );
    });
  });

  group('main() pre-warm timing', () {
    test('after pre-warming, the gate sees an authed carrier → /loads',
        () async {
      final prefs = await _prefsWithRole('carrier');
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(_RestoringAuth.new),
        ],
      );
      addTearDown(container.dispose);

      // What main() now does BEFORE the first frame.
      await container.read(authControllerProvider.future);

      final isAuthed =
          container.read(authControllerProvider).valueOrNull != null;
      final role = container.read(currentUserRoleSyncProvider);
      expect(isAuthed, isTrue);
      expect(
        resolveStartupRedirect(isAuthed: isAuthed, location: '/guest', role: role),
        '/loads',
      );
    });

    test(
        'without the pre-warm the session is still loading, so the gate keeps '
        'the user on the guest screen (the bug)', () async {
      final prefs = await _prefsWithRole('carrier');
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(_RestoringAuth.new),
        ],
      );
      addTearDown(container.dispose);

      // Old main(): no `await ...future`. On first read the controller is
      // AsyncLoading, valueOrNull is null → the gate treats the user as logged
      // out and leaves them on /guest (the login screen reappears).
      final isAuthedNow =
          container.read(authControllerProvider).valueOrNull != null;
      expect(isAuthedNow, isFalse);
      expect(
        resolveStartupRedirect(
            isAuthed: isAuthedNow, location: '/guest', role: 'carrier'),
        isNull, // stays on /guest — the regression
      );

      // The session was there all along; only the timing was wrong.
      await container.read(authControllerProvider.future);
      expect(container.read(authControllerProvider).valueOrNull, isNotNull);
    });
  });
}
