import 'package:loadme_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:loadme_mobile/features/auth/domain/entities/auth_check_result.dart';

abstract interface class AuthRepository {
  Future<AuthSession> login({required String phone, required String password});
  Future<AuthCheckResult> checkUserPhone(String phone);
  Future<AuthSession?> verifyOtp({
    required String phone,
    required String smsId,
    required String otp,
    required bool userFound,
  });
  Future<AuthSession> register({
    required String fullName,
    String? companyName,
    required String phone,
    required String smsId,
    required String otp,
  });
  Future<void> logout();
  Future<AuthSession?> getCachedSession();
}
