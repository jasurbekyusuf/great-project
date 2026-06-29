import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/core/use_case/use_case.dart';
import 'package:loadme_mobile/features/profile/domain/entities/profile_entity.dart';
import 'package:loadme_mobile/features/profile/domain/repositories/profile_repository.dart';

class UpdateProfileInput {
  const UpdateProfileInput({
    this.fullName,
    this.companyName,
    this.personType,
    this.telegramUsername,
    this.whatsappNumber,
  });

  final String? fullName;
  final String? companyName;
  final String? personType;
  final String? telegramUsername;
  final String? whatsappNumber;
}

class UpdateProfileUseCase implements UseCase<UpdateProfileInput, ProfileEntity> {
  const UpdateProfileUseCase(this._repo);
  final ProfileRepository _repo;

  @override
  AsyncResult<ProfileEntity> call(UpdateProfileInput input) =>
      _repo.updateProfile(
        fullName: input.fullName,
        companyName: input.companyName,
        personType: input.personType,
        telegramUsername: input.telegramUsername,
        whatsappNumber: input.whatsappNumber,
      );
}
