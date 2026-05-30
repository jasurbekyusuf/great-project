import 'package:dio/dio.dart';
import 'package:loadme_mobile/features/loads/data/dtos/load_dto.dart';
import 'package:loadme_mobile/shared/models/paginated_response.dart';

class LoadsRemoteDataSource {
  LoadsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PaginatedResponse<LoadDto>> getLoads(
      {required int page, required int limit}) async {
    final res = await _dio.post('/loads/get', data: {
      'page': page,
      'limit': limit,
    });
    return _parseLoadsResponse(res.data);
  }

  Future<PaginatedResponse<LoadDto>> getUserLoads({
    required int page,
    required int limit,
    required bool isActive,
    String? userGuid,
  }) async {
    final res = await _dio.post('/loads/get-user-loads', data: {
      'page': page,
      'offset': (page - 1) * limit,
      'limit': limit,
      'is_active': isActive,
      if (userGuid != null && userGuid.isNotEmpty) 'users_id': userGuid,
    });
    return _parseLoadsResponse(res.data);
  }

  Future<LoadDto> getLoadById(String id) async {
    final res = await _dio.post('/loads/get-load', data: {'load_id': id});
    return LoadDto.fromJson(
        (res.data['data'] ?? res.data) as Map<String, dynamic>);
  }

  Future<void> addLoad({
    required String fromAddress,
    required String toAddress,
    required String comment,
  }) async {
    await _dio.post('/loads/add', data: {
      'from_address': fromAddress,
      'to_address': toAddress,
      'comment': comment,
    });
  }

  Future<void> updateLoad({
    required String loadId,
    required String fromAddress,
    required String toAddress,
    required String comment,
  }) async {
    await _dio.post('/loads/update', data: {
      'load_id': loadId,
      'from_address': fromAddress,
      'to_address': toAddress,
      'comment': comment,
    });
  }

  Future<void> updateLoadStatus({
    required String guid,
    required bool isActive,
    String? closedPlatform,
  }) async {
    await _dio.post('/loads/update', data: {
      'guid': guid,
      'is_active': isActive,
      if (closedPlatform != null) 'closed_platform': closedPlatform,
    });
  }

  PaginatedResponse<LoadDto> _parseLoadsResponse(Object? raw) {
    final data = (raw is Map<String, dynamic> ? raw['data'] ?? raw : raw)
        as Map<String, dynamic>;
    final items = data['result'] ?? data['loads'] ?? const [];
    return PaginatedResponse(
      count: (data['count'] as num?)?.toInt() ??
          (items is List ? items.length : 0),
      result: items is List
          ? items
              .whereType<Map>()
              .map((json) => LoadDto.fromJson(Map<String, dynamic>.from(json)))
              .toList()
          : const [],
    );
  }
}
