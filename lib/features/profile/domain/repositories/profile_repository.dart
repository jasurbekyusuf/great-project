import 'package:loadme_mobile/features/profile/domain/entities/profile_entity.dart';

abstract interface class ProfileRepository {
  Future<ProfileEntity> getProfile();
}
