import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted storage for authentication tokens.
///
/// Backed by `flutter_secure_storage` which uses:
/// - Android: EncryptedSharedPreferences (AES-256, hardware-backed when available)
/// - iOS: Keychain
///
/// Use this **only** for credentials and short-lived secrets — anything else
/// belongs in `SharedPreferences` (cheap, sync).
abstract interface class SecureTokenStorage {
  Future<void> writeAccessToken(String token);
  Future<String?> readAccessToken();

  Future<void> writeRefreshToken(String token);
  Future<String?> readRefreshToken();

  Future<void> clear();
}

class SecureTokenStorageImpl implements SecureTokenStorage {
  SecureTokenStorageImpl([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _accessKey = 'auth.access_token';
  static const _refreshKey = 'auth.refresh_token';

  @override
  Future<void> writeAccessToken(String token) =>
      _storage.write(key: _accessKey, value: token);

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessKey);

  @override
  Future<void> writeRefreshToken(String token) =>
      _storage.write(key: _refreshKey, value: token);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
