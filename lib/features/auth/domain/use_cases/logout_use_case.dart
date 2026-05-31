import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/core/use_case/use_case.dart';
import 'package:loadme_mobile/features/auth/domain/repositories/auth_repository.dart';

class LogoutUseCase implements UseCaseNoInput<void> {
  const LogoutUseCase(this._repository);
  final AuthRepository _repository;

  @override
  AsyncResult<void> call() => _repository.logout();
}
