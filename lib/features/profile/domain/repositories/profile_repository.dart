import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/features/profile/domain/entities/profile_entity.dart';

abstract interface class ProfileRepository {
  AsyncResult<ProfileEntity> getProfile();
}
