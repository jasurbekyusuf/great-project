import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/app.dart';
import 'package:loadme_mobile/config/env/app_env.dart';
import 'package:loadme_mobile/core/storage/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Visible startup banner — confirms a fresh build picked up the fake-data
  // config. If this message doesn't appear in logcat, the device is still
  // running an older APK and needs a full rebuild.
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  final env = container.read(appEnvProvider);
  debugPrint('==== LOADME BUILD MARKER: useFakeData=${env.useFakeData} baseUrl=${env.baseApiUrl} ====');
  container.dispose();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const LoadmeApp(),
    ),
  );
}
