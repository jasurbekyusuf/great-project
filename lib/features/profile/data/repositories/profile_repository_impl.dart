import 'package:loadme_mobile/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:loadme_mobile/features/profile/domain/entities/profile_entity.dart';
import 'package:loadme_mobile/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote);
  final ProfileRemoteDataSource _remote;

  @override
  Future<ProfileEntity> getProfile() => _remote.getMyProfile();
}
