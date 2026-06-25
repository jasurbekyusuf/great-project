import 'package:loadme_mobile/features/auth/domain/entities/auth_session.dart';

/// Outcome of `POST /users/otp/verify/`.
///
/// - Login branch: [session] is set (tokens persisted, profile loaded).
/// - Registration branch: [registrationToken] is set — continue to the
///   register screen and pass it to `POST /users/register/`.
class VerifyOtpResult {
  const VerifyOtpResult({this.session, this.registrationToken});

  final AuthSession? session;
  final String? registrationToken;

  bool get needsRegistration =>
      session == null && (registrationToken?.isNotEmpty ?? false);
}
