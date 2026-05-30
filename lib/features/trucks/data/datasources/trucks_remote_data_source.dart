import 'package:dio/dio.dart';
import 'package:loadme_mobile/features/trucks/data/dtos/truck_dto.dart';
import 'package:loadme_mobile/shared/models/paginated_response.dart';

class TrucksRemoteDataSource {
  TrucksRemoteDataSource(this._dio);
  final Dio _dio;

  Future<PaginatedResponse<TruckDto>> getTrucks(
      {required int page, required int limit}) async {
    final res = await _dio
        .post('/post-truck/get-list', data: {'page': page, 'limit': limit});
    return _parseTrucksResponse(res.data);
  }

  Future<PaginatedResponse<TruckDto>> getMyPostTrucks({
    required int page,
    required int limit,
    required bool isActive,
  }) async {
    final res = await _dio.post('/post-truck/get-user-post-trucks', data: {
      'page': page,
      'offset': (page - 1) * limit,
      'limit': limit,
      'is_active': isActive,
    });
    return _parseTrucksResponse(res.data);
  }

  Future<PaginatedResponse<TruckDto>> getMyTrucks(
      {required int page, required int limit}) async {
    final res = await _dio.post('/trucks/get-user-trucks', data: {
      'page': page,
      'offset': (page - 1) * limit,
      'limit': limit,
    });
    return _parseTrucksResponse(res.data);
  }

  Future<Map<String, dynamic>> getTruckById(String id) async {
    final res = await _dio.post('/trucks/get-by-id?', data: {'truck_id': id});
    final data = res.data is Map<String, dynamic>
        ? (res.data['data'] ?? res.data) as Map<String, dynamic>
        : <String, dynamic>{};
    return data;
  }

  Future<void> updatePostTruckStatus({
    required String guid,
    required bool isActive,
  }) async {
    await _dio.post('/post-truck/update', data: {
      'guid': guid,
      'is_active': isActive,
    });
  }

  Future<void> updateTruckStatus({
    required String guid,
    required bool isActive,
  }) async {
    await _dio.put('/v2/items/trucks', data: {
      'data': {
        'guid': guid,
        'is_active': isActive,
      },
    });
  }

  PaginatedResponse<TruckDto> _parseTrucksResponse(Object? raw) {
    final data = (raw is Map<String, dynamic> ? raw['data'] ?? raw : raw)
        as Map<String, dynamic>;
    final items =
        data['result'] ?? data['post_trucks'] ?? data['trucks'] ?? const [];
    return PaginatedResponse.fromJson(
      {
        'count': (data['count'] as num?)?.toInt() ??
            (items is List ? items.length : 0),
        'result': items,
      },
      (json) => TruckDto.fromJson(json! as Map<String, dynamic>),
    );
  }
}
