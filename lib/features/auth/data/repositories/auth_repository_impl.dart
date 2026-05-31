import 'package:loadme_mobile/core/result/guard.dart';
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/core/storage/key_value_storage.dart';
import 'package:loadme_mobile/core/storage/secure_token_storage.dart';
import 'package:loadme_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:loadme_mobile/features/auth/domain/entities/auth_check_result.dart';
import 'package:loadme_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:loadme_mobile/features/auth/domain/repositories/auth_repository.dart';

/// Concrete repository.
///
/// Tokens go to encrypted [SecureTokenStorage]; the user profile JSON goes to
/// regular [KeyValueStorage] (it's not sensitive — non-PII subset).
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._storage, this._secure);

  final AuthRemoteDataSource _remote;
  final KeyValueStorage _storage;
  final SecureTokenStorage _secure;
  static const _tag = 'AuthRepository';

  static const _userDataKey = 'user_data';

  static AsyncResult<T> _guard<T>(Future<T> Function() block) =>
      Guard.run(block, tag: _tag);

  @override
  AsyncResult<AuthSession> login({required String phone, required String password}) =>
      _guard(() async {
        final dto = await _remote.loginWithPhonePassword(phone: phone, password: password);
        final token = dto.token ?? '';
        await _persistSession(token, dto.refreshToken, dto.userData);
        return _sessionFromTokens(token, dto.refreshToken, dto.userData);
      });

  @override
  AsyncResult<AuthCheckResult> checkUserPhone(String phone) =>
      _guard(() => _remote.checkUser(phone: phone));

  @override
  AsyncResult<AuthSession?> verifyOtp({
    required String phone,
    required String smsId,
    required String otp,
    required bool userFound,
  }) =>
      _guard(() async {
        final data = await _remote.verifyOtp(phone: phone, smsId: smsId, otp: otp);
        final tokenData = data['token'];
        final accessToken =
            tokenData is Map<String, dynamic> ? tokenData['access_token']?.toString() : null;
        final refreshToken =
            tokenData is Map<String, dynamic> ? tokenData['refresh_token']?.toString() : null;
        final userData = data['user_data'] as Map<String, dynamic>?;
        if (accessToken == null || accessToken.isEmpty) return null;
        await _persistSession(accessToken, refreshToken, userData);
        return _sessionFromTokens(accessToken, refreshToken, userData);
      });

  @override
  AsyncResult<AuthSession> register({
    required String fullName,
    String? companyName,
    required String phone,
    required String smsId,
    required String otp,
  }) =>
      _guard(() async {
        final dto = await _remote.register(
          fullName: fullName,
          companyName: companyName,
          phone: phone,
          smsId: smsId,
          otp: otp,
        );
        final token = dto.token ?? '';
        await _persistSession(token, dto.refreshToken, dto.userData);
        return _sessionFromTokens(token, dto.refreshToken, dto.userData);
      });

  @override
  AsyncResult<void> logout() => _guard(() async {
        await _secure.clear();
        await _storage.remove(_userDataKey);
      });

  @override
  AsyncResult<AuthSession?> getCachedSession() => _guard(() async {
        final token = await _secure.readAccessToken();
        if (token == null || token.isEmpty) return null;
        final user = await _storage.readJson(_userDataKey);
        return AuthSession(
          token: token,
          refreshToken: await _secure.readRefreshToken(),
          userGuid: user?['guid']?.toString(),
          fullName: user?['full_name']?.toString(),
        );
      });

  // ---- helpers ------------------------------------------------------------

  Future<void> _persistSession(
    String token,
    String? refreshToken,
    Map<String, dynamic>? userData,
  ) async {
    await _secure.writeAccessToken(token);
    if (refreshToken != null) await _secure.writeRefreshToken(refreshToken);
    if (userData != null) await _storage.writeJson(_userDataKey, userData);
  }

  AuthSession _sessionFromTokens(
    String token,
    String? refreshToken,
    Map<String, dynamic>? userData,
  ) {
    return AuthSession(
      token: token,
      refreshToken: refreshToken,
      userGuid: userData?['guid']?.toString(),
      fullName: userData?['full_name']?.toString(),
    );
  }
}
