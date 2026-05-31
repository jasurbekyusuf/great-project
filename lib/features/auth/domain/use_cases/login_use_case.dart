import 'package:equatable/equatable.dart';
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/core/use_case/use_case.dart';
import 'package:loadme_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:loadme_mobile/features/auth/domain/repositories/auth_repository.dart';

class LoginInput extends Equatable {
  const LoginInput({required this.phone, required this.password});
  final String phone;
  final String password;

  @override
  List<Object?> get props => [phone, password];
}

class LoginUseCase implements UseCase<LoginInput, AuthSession> {
  const LoginUseCase(this._repository);
  final AuthRepository _repository;

  @override
  AsyncResult<AuthSession> call(LoginInput input) =>
      _repository.login(phone: input.phone, password: input.password);
}
