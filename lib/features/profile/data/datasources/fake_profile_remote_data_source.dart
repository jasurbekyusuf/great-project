import 'package:dio/dio.dart';
import 'package:loadme_mobile/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:loadme_mobile/features/profile/domain/entities/profile_entity.dart';

class FakeProfileRemoteDataSource extends ProfileRemoteDataSource {
  FakeProfileRemoteDataSource() : super(Dio());

  @override
  Future<ProfileEntity> getMyProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return const ProfileEntity(
      guid: 'fake-user-guid',
      fullName: 'Test Foydalanuvchi',
      phone: '+998900000000',
    );
  }
}
