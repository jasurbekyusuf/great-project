import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Carries the multi-step auth state across the welcome → verify → register
/// screens. Mirrors the web `loginStore`: phone + channel + detected purpose,
/// then the OTP code, then (for new users) the `registration_token` and the
/// chosen role / person type.
class AuthFlowState {
  const AuthFlowState({
    this.phone = '',
    this.channel = 'sms',
    this.purpose = 'login',
    this.userFound = false,
    this.otp = '',
    this.registrationToken = '',
    this.role = 'carrier',
    this.personType = 'individual',
  });

  final String phone;

  /// OTP delivery channel: `'sms'` (UZ +998 only) | `'telegram'`.
  final String channel;

  /// Backend-detected flow: `'login'` (existing user) | `'registration'`.
  final String purpose;

  final bool userFound;
  final String otp;

  /// Short-lived token returned by verify when the user must still register.
  final String registrationToken;

  /// Selected role during registration: shipper | broker | carrier (app role).
  final String role;

  /// Account type: individual | legal (company).
  final String personType;

  AuthFlowState copyWith({
    String? phone,
    String? channel,
    String? purpose,
    bool? userFound,
    String? otp,
    String? registrationToken,
    String? role,
    String? personType,
  }) {
    return AuthFlowState(
      phone: phone ?? this.phone,
      channel: channel ?? this.channel,
      purpose: purpose ?? this.purpose,
      userFound: userFound ?? this.userFound,
      otp: otp ?? this.otp,
      registrationToken: registrationToken ?? this.registrationToken,
      role: role ?? this.role,
      personType: personType ?? this.personType,
    );
  }
}

class AuthFlowNotifier extends StateNotifier<AuthFlowState> {
  AuthFlowNotifier() : super(const AuthFlowState());

  void setPhoneCheckResult({
    required String phone,
    required String channel,
    required String purpose,
  }) {
    state = state.copyWith(
      phone: phone,
      channel: channel,
      purpose: purpose,
      userFound: purpose == 'login',
    );
  }

  void setOtp(String otp) => state = state.copyWith(otp: otp);

  void setRegistrationToken(String token) =>
      state = state.copyWith(registrationToken: token);

  void setRole(String role) => state = state.copyWith(role: role);

  void setPersonType(String personType) =>
      state = state.copyWith(personType: personType);

  void reset() => state = const AuthFlowState();
}

final authFlowProvider = StateNotifierProvider<AuthFlowNotifier, AuthFlowState>((_) => AuthFlowNotifier());
