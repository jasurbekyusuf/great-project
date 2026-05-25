import 'package:dio/dio.dart';
import 'package:loadme_mobile/features/trucks/data/dtos/truck_dto.dart';
import 'package:loadme_mobile/shared/models/paginated_response.dart';

class TrucksRemoteDataSource {
  TrucksRemoteDataSource(this._dio);
  final Dio _dio;

  Future<PaginatedResponse<TruckDto>> getTrucks({required int page, required int limit}) async {
    final res = await _dio.post('/post-truck/get-list', data: {'page': page, 'limit': limit});
    return PaginatedResponse.fromJson(
      (res.data['data'] ?? res.data) as Map<String, dynamic>,
      (json) => TruckDto.fromJson(json! as Map<String, dynamic>),
    );
  }
}
