import 'package:loadme_mobile/core/result/guard.dart';
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:loadme_mobile/features/profile/domain/entities/profile_entity.dart';
import 'package:loadme_mobile/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote);
  final ProfileRemoteDataSource _remote;
  static const _tag = 'ProfileRepository';

  @override
  AsyncResult<ProfileEntity> getProfile() =>
      Guard.run(() => _remote.getMyProfile(), tag: _tag);
}
