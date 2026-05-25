import 'package:dio/dio.dart';
import 'package:loadme_mobile/features/auth/data/dtos/auth_session_dto.dart';
import 'package:loadme_mobile/features/auth/domain/entities/auth_check_result.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AuthSessionDto> loginWithPhonePassword({required String phone, required String password}) async {
    final res = await _dio.post('/auth/login-with-phone-password', data: {
      'phone': phone,
      'password': password,
    });
    return AuthSessionDto.fromJson((res.data['data'] ?? res.data) as Map<String, dynamic>);
  }

  Future<AuthCheckResult> checkUser({required String phone}) async {
    final res = await _dio.post('/auth/check-user', data: {'phone': phone});
    final data = (res.data['data'] ?? res.data) as Map<String, dynamic>;
    return AuthCheckResult(
      smsId: data['sms_id']?.toString() ?? '',
      userFound: (data['user_found'] as bool?) ?? false,
    );
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String smsId,
    required String otp,
  }) async {
    final res = await _dio.post('/auth/confirm-otp', data: {
      'phone': phone,
      'sms_id': smsId,
      'otp': otp,
    });
    return (res.data['data'] ?? res.data) as Map<String, dynamic>;
  }

  Future<AuthSessionDto> register({
    required String fullName,
    String? companyName,
    required String phone,
    required String smsId,
    required String otp,
  }) async {
    final res = await _dio.post('/auth/register', data: {
      'full_name': fullName,
      'company_name': companyName,
      'phone': phone,
      'sms_id': smsId,
      'otp': otp,
    });
    return AuthSessionDto.fromJson((res.data['data'] ?? res.data) as Map<String, dynamic>);
  }
}
