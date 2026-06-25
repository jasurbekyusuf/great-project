import 'package:loadme_mobile/core/result/guard.dart';
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/core/storage/key_value_storage.dart';
import 'package:loadme_mobile/core/storage/secure_token_storage.dart';
import 'package:loadme_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:loadme_mobile/features/auth/domain/entities/auth_check_result.dart';
import 'package:loadme_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:loadme_mobile/features/auth/domain/entities/verify_otp_result.dart';
import 'package:loadme_mobile/features/auth/domain/repositories/auth_repository.dart';

/// Concrete repository.
///
/// Tokens go to encrypted [SecureTokenStorage]; the user profile JSON goes to
/// regular [KeyValueStorage] (a non-PII subset). The backend role `driver` is
/// normalised back to the app's `carrier` on read so the rest of the app keeps
/// using a single vocabulary.
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
        return _finishLogin(dto.access ?? '', dto.refresh, dto.user);
      });

  @override
  AsyncResult<AuthCheckResult> checkUserPhone({
    required String phone,
    required String channel,
  }) =>
      _guard(() => _remote.sendOtp(phone: phone, channel: channel));

  @override
  AsyncResult<VerifyOtpResult> verifyOtp({
    required String phone,
    required String channel,
    required String purpose,
    required String code,
  }) =>
      _guard(() async {
        final data = await _remote.verifyOtp(
          phone: phone,
          channel: channel,
          purpose: purpose,
          code: code,
        );
        final access = data['access']?.toString();
        final refresh = data['refresh']?.toString();
        if (access != null && access.isNotEmpty) {
          final session = await _finishLogin(
            access,
            refresh,
            data['user'] is Map ? Map<String, dynamic>.from(data['user'] as Map) : null,
          );
          return VerifyOtpResult(session: session);
        }
        return VerifyOtpResult(
          registrationToken: data['registration_token']?.toString(),
        );
      });

  @override
  AsyncResult<AuthSession> register({
    required String registrationToken,
    required String role,
    required String personType,
    String? fullName,
    String? companyName,
  }) =>
      _guard(() async {
        final dto = await _remote.register(
          registrationToken: registrationToken,
          role: _roleToBackend(role),
          personType: personType,
          fullName: fullName,
          companyName: companyName,
        );
        return _finishLogin(dto.access ?? '', dto.refresh, dto.user);
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

  /// Persists tokens, then loads the canonical profile from `/users/me/`
  /// (verify/register responses often omit it), normalises and caches it, and
  /// returns the [AuthSession].
  Future<AuthSession> _finishLogin(
    String access,
    String? refresh,
    Map<String, dynamic>? embeddedUser,
  ) async {
    await _secure.writeAccessToken(access);
    if (refresh != null && refresh.isNotEmpty) {
      await _secure.writeRefreshToken(refresh);
    }

    Map<String, dynamic>? me = embeddedUser;
    try {
      me = await _remote.getMe();
    } catch (_) {
      // Fall back to whatever the auth response carried (may be null).
    }

    final user = _normalizeUser(me);
    if (user != null) await _storage.writeJson(_userDataKey, user);

    return AuthSession(
      token: access,
      refreshToken: refresh,
      userGuid: user?['guid']?.toString(),
      fullName: user?['full_name']?.toString(),
    );
  }

  /// Maps the backend `/me/` shape onto the flat blob the app expects, with
  /// `role` stored as a single-item list of the app role (carrier|broker|
  /// shipper) and convenience `guid`/`phone`/`full_name` fields hoisted up.
  Map<String, dynamic>? _normalizeUser(Map<String, dynamic>? me) {
    if (me == null) return null;
    final rawRole = me['role'];
    final roleStr = rawRole is List
        ? (rawRole.isNotEmpty ? rawRole.first.toString() : '')
        : (rawRole?.toString() ?? '');
    final profile = me['profile'] is Map
        ? Map<String, dynamic>.from(me['profile'] as Map)
        : const <String, dynamic>{};
    return {
      ...me,
      'role': [_roleFromBackend(roleStr)],
      'guid': me['id']?.toString() ?? me['guid']?.toString(),
      'phone': me['phone_number']?.toString() ?? me['phone']?.toString(),
      'full_name': profile['full_name']?.toString() ??
          me['display_name']?.toString() ??
          me['full_name']?.toString(),
    };
  }

  String _roleToBackend(String role) => role == 'carrier' ? 'driver' : role;

  String _roleFromBackend(String role) => role == 'driver' ? 'carrier' : role;
}
