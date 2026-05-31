import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/storage/key_value_storage.dart';
import 'package:loadme_mobile/core/storage/secure_token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Injected from `main()` after `SharedPreferences.getInstance()` resolves.
final sharedPreferencesProvider = Provider<SharedPreferences>((_) {
  throw UnimplementedError('Override in main');
});

/// General-purpose key-value cache. Use for non-sensitive state
/// (selected language, theme, last seen tab, etc.).
final storageProvider = Provider<KeyValueStorage>(
  (ref) => SharedPrefsStorage(ref.watch(sharedPreferencesProvider)),
);

/// Encrypted token storage. Use only for auth tokens and other secrets.
final secureTokenStorageProvider = Provider<SecureTokenStorage>(
  (_) => SecureTokenStorageImpl(),
);
