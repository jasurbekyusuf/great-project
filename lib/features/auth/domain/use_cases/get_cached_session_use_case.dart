import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/core/use_case/use_case.dart';
import 'package:loadme_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:loadme_mobile/features/auth/domain/repositories/auth_repository.dart';

class GetCachedSessionUseCase implements UseCaseNoInput<AuthSession?> {
  const GetCachedSessionUseCase(this._repository);
  final AuthRepository _repository;

  @override
  AsyncResult<AuthSession?> call() => _repository.getCachedSession();
}
