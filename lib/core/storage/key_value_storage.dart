import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class KeyValueStorage {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> remove(String key);
  Future<void> writeJson(String key, Map<String, dynamic> value);
  Future<Map<String, dynamic>?> readJson(String key);
}

class SharedPrefsStorage implements KeyValueStorage {
  SharedPrefsStorage(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<void> write(String key, String value) async => _prefs.setString(key, value);

  @override
  Future<String?> read(String key) async => _prefs.getString(key);

  @override
  Future<void> remove(String key) async => _prefs.remove(key);

  @override
  Future<void> writeJson(String key, Map<String, dynamic> value) async {
    await _prefs.setString(key, jsonEncode(value));
  }

  @override
  Future<Map<String, dynamic>?> readJson(String key) async {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
