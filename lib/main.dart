import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/app.dart';
import 'package:loadme_mobile/config/env/app_env.dart';
import 'package:loadme_mobile/core/di/register_dependencies.dart';
import 'package:loadme_mobile/core/logging/app_logger.dart';
import 'package:loadme_mobile/core/storage/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  await registerDependencies();

  // Lightweight bootstrap log — only visible in debug builds.
  final probe = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  final env = probe.read(appEnvProvider);
  AppLogger.tagged('Bootstrap').i(
    'env=${env.useFakeData ? 'fake' : 'live'} baseUrl=${env.baseApiUrl}',
  );
  probe.dispose();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const LoadmeApp(),
    ),
  );
}
