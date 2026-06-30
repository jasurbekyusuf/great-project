import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/app.dart';
import 'package:loadme_mobile/config/env/app_env.dart';
import 'package:loadme_mobile/core/logging/app_logger.dart';
import 'package:loadme_mobile/core/storage/providers.dart';
import 'package:loadme_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // One container for the whole app lifetime so the session we restore below is
  // the *same* instance the router reads on its first redirect.
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  final env = container.read(appEnvProvider);
  AppLogger.tagged('Bootstrap').i(
    'env=${env.environment.name} baseUrl=${env.baseApiUrl}',
  );

  // Restore the persisted login BEFORE the first frame. Otherwise the router's
  // very first redirect runs while authControllerProvider is still AsyncLoading
  // (valueOrNull == null), so an already-logged-in user is bounced to /guest on
  // every cold start. Reading `.future` resolves the cached session (secure
  // storage; no network) and never throws — build() folds failures to null.
  await container.read(authControllerProvider.future);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const LoadmeApp(),
    ),
  );
}
