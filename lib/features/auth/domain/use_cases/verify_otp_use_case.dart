import 'package:equatable/equatable.dart';
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/core/use_case/use_case.dart';
import 'package:loadme_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:loadme_mobile/features/auth/domain/repositories/auth_repository.dart';

class VerifyOtpInput extends Equatable {
  const VerifyOtpInput({
    required this.phone,
    required this.smsId,
    required this.otp,
    required this.userFound,
  });

  final String phone;
  final String smsId;
  final String otp;
  final bool userFound;

  @override
  List<Object?> get props => [phone, smsId, otp, userFound];
}

class VerifyOtpUseCase implements UseCase<VerifyOtpInput, AuthSession?> {
  const VerifyOtpUseCase(this._repository);
  final AuthRepository _repository;

  @override
  AsyncResult<AuthSession?> call(VerifyOtpInput input) => _repository.verifyOtp(
        phone: input.phone,
        smsId: input.smsId,
        otp: input.otp,
        userFound: input.userFound,
      );
}
