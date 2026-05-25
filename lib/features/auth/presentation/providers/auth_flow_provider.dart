import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthFlowState {
  const AuthFlowState({
    this.phone = '',
    this.smsId = '',
    this.userFound = false,
    this.otp = '',
  });

  final String phone;
  final String smsId;
  final bool userFound;
  final String otp;

  AuthFlowState copyWith({
    String? phone,
    String? smsId,
    bool? userFound,
    String? otp,
  }) {
    return AuthFlowState(
      phone: phone ?? this.phone,
      smsId: smsId ?? this.smsId,
      userFound: userFound ?? this.userFound,
      otp: otp ?? this.otp,
    );
  }
}

class AuthFlowNotifier extends StateNotifier<AuthFlowState> {
  AuthFlowNotifier() : super(const AuthFlowState());

  void setPhoneCheckResult({
    required String phone,
    required String smsId,
    required bool userFound,
  }) {
    state = state.copyWith(phone: phone, smsId: smsId, userFound: userFound);
  }

  void setOtp(String otp) => state = state.copyWith(otp: otp);

  void reset() => state = const AuthFlowState();
}

final authFlowProvider = StateNotifierProvider<AuthFlowNotifier, AuthFlowState>((_) => AuthFlowNotifier());
