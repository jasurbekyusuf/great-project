import 'package:equatable/equatable.dart';
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/core/use_case/use_case.dart';
import 'package:loadme_mobile/features/auth/domain/entities/auth_check_result.dart';
import 'package:loadme_mobile/features/auth/domain/repositories/auth_repository.dart';

class SendOtpParams extends Equatable {
  const SendOtpParams({required this.phone, required this.channel});

  final String phone;
  final String channel; // 'sms' | 'telegram'

  @override
  List<Object?> get props => [phone, channel];
}

/// Sends an OTP and reports whether the flow is a login or a registration.
///
/// Wraps a single repository call so presentation never reaches for the
/// repository directly — keeping a stable, testable contract.
class CheckUserPhoneUseCase implements UseCase<SendOtpParams, AuthCheckResult> {
  const CheckUserPhoneUseCase(this._repository);
  final AuthRepository _repository;

  @override
  AsyncResult<AuthCheckResult> call(SendOtpParams params) =>
      _repository.checkUserPhone(
        phone: params.phone.trim(),
        channel: params.channel,
      );
}
