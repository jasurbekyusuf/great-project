import 'package:equatable/equatable.dart';
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/core/use_case/use_case.dart';
import 'package:loadme_mobile/features/auth/domain/entities/verify_otp_result.dart';
import 'package:loadme_mobile/features/auth/domain/repositories/auth_repository.dart';

class VerifyOtpInput extends Equatable {
  const VerifyOtpInput({
    required this.phone,
    required this.channel,
    required this.purpose,
    required this.code,
  });

  final String phone;
  final String channel;
  final String purpose;
  final String code;

  @override
  List<Object?> get props => [phone, channel, purpose, code];
}

class VerifyOtpUseCase implements UseCase<VerifyOtpInput, VerifyOtpResult> {
  const VerifyOtpUseCase(this._repository);
  final AuthRepository _repository;

  @override
  AsyncResult<VerifyOtpResult> call(VerifyOtpInput input) =>
      _repository.verifyOtp(
        phone: input.phone,
        channel: input.channel,
        purpose: input.purpose,
        code: input.code,
      );
}
