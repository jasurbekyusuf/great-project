import 'package:dio/dio.dart';
import 'package:loadme_mobile/features/auth/data/dtos/auth_session_dto.dart';
import 'package:loadme_mobile/features/auth/domain/entities/auth_check_result.dart';

/// Talks to the real LoadMe backend (Django + DRF) under `/api/v1`.
///
/// Response envelope is `{ success: true, data: {...} }`; [_unwrap] peels the
/// `data` layer so callers see the inner object directly. Auth is a single
/// unified OTP flow — there is no `check-user` and no `sms_id`.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Map<String, dynamic> _unwrap(Response<dynamic> res) {
    final body = res.data;
    if (body is Map && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    if (body is Map) return Map<String, dynamic>.from(body);
    return <String, dynamic>{};
  }

  /// `POST /users/otp/send/` — sends an OTP and reports whether this phone is a
  /// login or a registration. [channel] is `'sms'` (UZ +998 only) or
  /// `'telegram'`.
  Future<AuthCheckResult> sendOtp({
    required String phone,
    required String channel,
  }) async {
    final res = await _dio.post<dynamic>(
      '/users/otp/send/',
      data: {'phone_number': phone, 'channel': channel},
    );
    final data = _unwrap(res);
    return AuthCheckResult(purpose: (data['purpose'] ?? 'login').toString());
  }

  /// `POST /users/otp/verify/` — returns `{ access, refresh, user? }` for a
  /// login, or `{ registration_token }` when the user still needs to register.
  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String channel,
    required String purpose,
    required String code,
  }) async {
    final res = await _dio.post<dynamic>(
      '/users/otp/verify/',
      data: {
        'phone_number': phone,
        'channel': channel,
        'purpose': purpose,
        'code': code,
      },
    );
    return _unwrap(res);
  }

  /// `POST /users/register/` (multipart) — finalises a new account using the
  /// `registration_token` from verify. [role] must already be backend-mapped
  /// (carrier → driver). Sends `full_name` for individuals, `company_name` for
  /// legal entities.
  Future<AuthSessionDto> register({
    required String registrationToken,
    required String role,
    required String personType,
    String? fullName,
    String? companyName,
  }) async {
    final form = FormData.fromMap({
      'registration_token': registrationToken,
      'role': role,
      'person_type': personType,
      if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
      if (companyName != null && companyName.isNotEmpty)
        'company_name': companyName,
    });
    final res = await _dio.post<dynamic>('/users/register/', data: form);
    return AuthSessionDto.fromJson(_unwrap(res));
  }

  /// `GET /users/me/` — the authenticated user profile (role, person_type and
  /// a nested `profile` object). Needs a valid bearer token.
  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get<dynamic>('/users/me/');
    return _unwrap(res);
  }

  /// `POST /users/login/` — password login. Kept for completeness; the app's
  /// primary path is the OTP flow above.
  Future<AuthSessionDto> loginWithPhonePassword({
    required String phone,
    required String password,
  }) async {
    final res = await _dio.post<dynamic>(
      '/users/login/',
      data: {'phone_number': phone, 'password': password},
    );
    return AuthSessionDto.fromJson(_unwrap(res));
  }
}
