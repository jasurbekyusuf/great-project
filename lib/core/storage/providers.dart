import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'key_value_storage.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((_) {
  throw UnimplementedError('Override in main');
});

final storageProvider = Provider<KeyValueStorage>((ref) {
  return SharedPrefsStorage(ref.watch(sharedPreferencesProvider));
});
