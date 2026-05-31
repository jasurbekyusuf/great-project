import 'package:loadme_mobile/core/errors/app_failure.dart' show AppFailure;
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/features/auth/domain/entities/auth_check_result.dart';
import 'package:loadme_mobile/features/auth/domain/entities/auth_session.dart';

/// Domain contract for authentication operations.
///
/// Every method returns a [Result] / [AsyncResult] — no thrown exceptions
/// cross the layer boundary. The data layer maps Dio/cache errors into
/// [AppFailure] subtypes before returning them as `Left`.
abstract interface class AuthRepository {
  AsyncResult<AuthSession> login({required String phone, required String password});

  AsyncResult<AuthCheckResult> checkUserPhone(String phone);

  AsyncResult<AuthSession?> verifyOtp({
    required String phone,
    required String smsId,
    required String otp,
    required bool userFound,
  });

  AsyncResult<AuthSession> register({
    required String fullName,
    String? companyName,
    required String phone,
    required String smsId,
    required String otp,
  });

  AsyncResult<void> logout();

  AsyncResult<AuthSession?> getCachedSession();
}
