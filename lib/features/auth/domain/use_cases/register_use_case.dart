import 'package:equatable/equatable.dart';
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/core/use_case/use_case.dart';
import 'package:loadme_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:loadme_mobile/features/auth/domain/repositories/auth_repository.dart';

class RegisterInput extends Equatable {
  const RegisterInput({
    required this.fullName,
    required this.phone,
    required this.smsId,
    required this.otp,
    this.companyName,
  });

  final String fullName;
  final String? companyName;
  final String phone;
  final String smsId;
  final String otp;

  @override
  List<Object?> get props => [fullName, companyName, phone, smsId, otp];
}

class RegisterUseCase implements UseCase<RegisterInput, AuthSession> {
  const RegisterUseCase(this._repository);
  final AuthRepository _repository;

  @override
  AsyncResult<AuthSession> call(RegisterInput input) => _repository.register(
        fullName: input.fullName,
        companyName: input.companyName,
        phone: input.phone,
        smsId: input.smsId,
        otp: input.otp,
      );
}
