import 'package:loadme_mobile/core/errors/app_failure.dart' show AppFailure;
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/features/auth/domain/entities/auth_check_result.dart';
import 'package:loadme_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:loadme_mobile/features/auth/domain/entities/verify_otp_result.dart';

/// Domain contract for authentication operations.
///
/// Every method returns a [Result] / [AsyncResult] — no thrown exceptions
/// cross the layer boundary. The data layer maps Dio/cache errors into
/// [AppFailure] subtypes before returning them as `Left`.
abstract interface class AuthRepository {
  AsyncResult<AuthSession> login({required String phone, required String password});

  /// Sends an OTP via [channel] (`'sms'` | `'telegram'`) and reports whether
  /// this is a login or a registration.
  AsyncResult<AuthCheckResult> checkUserPhone({
    required String phone,
    required String channel,
  });

  /// Verifies the OTP. On the login branch a session is returned (tokens
  /// persisted, profile fetched); on the registration branch a
  /// `registration_token` is returned instead.
  AsyncResult<VerifyOtpResult> verifyOtp({
    required String phone,
    required String channel,
    required String purpose,
    required String code,
  });

  /// Finalises registration with the `registration_token` from verify. [role]
  /// is the app role (carrier|broker|shipper); the data layer maps
  /// carrier → driver for the backend.
  AsyncResult<AuthSession> register({
    required String registrationToken,
    required String role,
    required String personType,
    String? fullName,
    String? companyName,
  });

  AsyncResult<void> logout();

  AsyncResult<AuthSession?> getCachedSession();
}
