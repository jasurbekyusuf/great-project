import 'package:equatable/equatable.dart';
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/core/use_case/use_case.dart';
import 'package:loadme_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:loadme_mobile/features/auth/domain/repositories/auth_repository.dart';

class RegisterInput extends Equatable {
  const RegisterInput({
    required this.registrationToken,
    required this.role,
    required this.personType,
    this.fullName,
    this.companyName,
  });

  final String registrationToken;
  final String role;
  final String personType;
  final String? fullName;
  final String? companyName;

  @override
  List<Object?> get props =>
      [registrationToken, role, personType, fullName, companyName];
}

class RegisterUseCase implements UseCase<RegisterInput, AuthSession> {
  const RegisterUseCase(this._repository);
  final AuthRepository _repository;

  @override
  AsyncResult<AuthSession> call(RegisterInput input) => _repository.register(
        registrationToken: input.registrationToken,
        role: input.role,
        personType: input.personType,
        fullName: input.fullName,
        companyName: input.companyName,
      );
}
