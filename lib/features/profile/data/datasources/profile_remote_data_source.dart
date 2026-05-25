import 'package:dio/dio.dart';
import 'package:loadme_mobile/features/profile/domain/entities/profile_entity.dart';

class ProfileRemoteDataSource {
  ProfileRemoteDataSource(this._dio);
  final Dio _dio;

  Future<ProfileEntity> getMyProfile() async {
    final res = await _dio.post('/users/get-by-token', data: {});
    final data = (res.data['data'] ?? res.data) as Map<String, dynamic>;
    return ProfileEntity(
      guid: data['guid']?.toString() ?? '',
      fullName: data['full_name']?.toString() ?? '-',
      phone: data['phone']?.toString(),
    );
  }
}
