import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/core/use_case/use_case.dart';
import 'package:loadme_mobile/features/profile/domain/entities/profile_entity.dart';
import 'package:loadme_mobile/features/profile/domain/repositories/profile_repository.dart';

class GetProfileUseCase implements UseCaseNoInput<ProfileEntity> {
  const GetProfileUseCase(this._repo);
  final ProfileRepository _repo;

  @override
  AsyncResult<ProfileEntity> call() => _repo.getProfile();
}
