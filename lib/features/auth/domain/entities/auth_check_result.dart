/// Result of `POST /users/otp/send/`.
///
/// The backend auto-detects whether the phone belongs to an existing user
/// (`purpose == 'login'`) or a brand-new one (`purpose == 'registration'`) and
/// sends the OTP over the chosen channel. There is no separate "check-user"
/// step and no `sms_id`; [purpose] is carried forward into the verify call.
class AuthCheckResult {
  const AuthCheckResult({required this.purpose});

  final String purpose; // 'login' | 'registration'

  bool get userFound => purpose == 'login';
}
