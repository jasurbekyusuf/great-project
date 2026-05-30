import 'package:dio/dio.dart';
import 'package:loadme_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:loadme_mobile/features/auth/data/dtos/auth_session_dto.dart';
import 'package:loadme_mobile/features/auth/domain/entities/auth_check_result.dart';

// In-memory stand-in for the real auth API. Activated when `AppEnv.useFakeData`
// is true. Accepts any phone/password/OTP and returns a deterministic session.
class FakeAuthRemoteDataSource extends AuthRemoteDataSource {
  FakeAuthRemoteDataSource() : super(Dio());

  static const _fakeUser = {
    'guid': 'fake-user-guid',
    'full_name': 'Test Foydalanuvchi',
    'phone': '+998900000000',
    'role': ['shipper'],
  };

  @override
  Future<AuthSessionDto> loginWithPhonePassword({required String phone, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return AuthSessionDto(
      token: 'fake-access-token',
      refreshToken: 'fake-refresh-token',
      userData: {..._fakeUser, 'phone': phone},
    );
  }

  @override
  Future<AuthCheckResult> checkUser({required String phone}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return const AuthCheckResult(smsId: 'fake-sms-id', userFound: true);
  }

  @override
  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String smsId,
    required String otp,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return {
      'token': {
        'access_token': 'fake-access-token',
        'refresh_token': 'fake-refresh-token',
      },
      'user_data': {..._fakeUser, 'phone': phone},
    };
  }

  @override
  Future<AuthSessionDto> register({
    required String fullName,
    String? companyName,
    required String phone,
    required String smsId,
    required String otp,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return AuthSessionDto(
      token: 'fake-access-token',
      refreshToken: 'fake-refresh-token',
      userData: {
        ..._fakeUser,
        'phone': phone,
        'full_name': fullName,
        if (companyName != null) 'company_name': companyName,
      },
    );
  }
}
