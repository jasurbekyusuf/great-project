import 'package:loadme_mobile/core/storage/key_value_storage.dart';
import 'package:loadme_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:loadme_mobile/features/auth/domain/entities/auth_check_result.dart';
import 'package:loadme_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:loadme_mobile/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._storage);

  final AuthRemoteDataSource _remote;
  final KeyValueStorage _storage;

  @override
  Future<AuthSession> login({required String phone, required String password}) async {
    final dto = await _remote.loginWithPhonePassword(phone: phone, password: password);
    final token = dto.token ?? '';
    await _storage.write('access_token', token);
    if (dto.refreshToken != null) await _storage.write('refresh_token', dto.refreshToken!);
    if (dto.userData != null) await _storage.writeJson('user_data', dto.userData!);

    return AuthSession(
      token: token,
      refreshToken: dto.refreshToken,
      userGuid: dto.userData?['guid']?.toString(),
      fullName: dto.userData?['full_name']?.toString(),
    );
  }

  @override
  Future<AuthCheckResult> checkUserPhone(String phone) {
    return _remote.checkUser(phone: phone);
  }

  @override
  Future<AuthSession?> verifyOtp({
    required String phone,
    required String smsId,
    required String otp,
    required bool userFound,
  }) async {
    final data = await _remote.verifyOtp(phone: phone, smsId: smsId, otp: otp);
    final tokenData = data['token'];
    final accessToken = tokenData is Map<String, dynamic> ? tokenData['access_token']?.toString() : null;
    final refreshToken = tokenData is Map<String, dynamic> ? tokenData['refresh_token']?.toString() : null;
    final userData = data['user_data'] as Map<String, dynamic>?;

    if (accessToken == null || accessToken.isEmpty) return null;
    await _storage.write('access_token', accessToken);
    if (refreshToken != null) await _storage.write('refresh_token', refreshToken);
    if (userData != null) await _storage.writeJson('user_data', userData);
    return AuthSession(
      token: accessToken,
      refreshToken: refreshToken,
      userGuid: userData?['guid']?.toString(),
      fullName: userData?['full_name']?.toString(),
    );
  }

  @override
  Future<AuthSession> register({
    required String fullName,
    String? companyName,
    required String phone,
    required String smsId,
    required String otp,
  }) async {
    final dto = await _remote.register(
      fullName: fullName,
      companyName: companyName,
      phone: phone,
      smsId: smsId,
      otp: otp,
    );
    final token = dto.token ?? '';
    await _storage.write('access_token', token);
    if (dto.refreshToken != null) await _storage.write('refresh_token', dto.refreshToken!);
    if (dto.userData != null) await _storage.writeJson('user_data', dto.userData!);
    return AuthSession(
      token: token,
      refreshToken: dto.refreshToken,
      userGuid: dto.userData?['guid']?.toString(),
      fullName: dto.userData?['full_name']?.toString(),
    );
  }

  @override
  Future<AuthSession?> getCachedSession() async {
    final token = await _storage.read('access_token');
    if (token == null || token.isEmpty) return null;
    final user = await _storage.readJson('user_data');
    return AuthSession(
      token: token,
      refreshToken: await _storage.read('refresh_token'),
      userGuid: user?['guid']?.toString(),
      fullName: user?['full_name']?.toString(),
    );
  }

  @override
  Future<void> logout() async {
    await _storage.remove('access_token');
    await _storage.remove('refresh_token');
    await _storage.remove('user_data');
  }
}
