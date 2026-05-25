import 'package:dio/dio.dart';
import 'package:loadme_mobile/features/loads/data/dtos/load_dto.dart';
import 'package:loadme_mobile/shared/models/paginated_response.dart';

class LoadsRemoteDataSource {
  LoadsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PaginatedResponse<LoadDto>> getLoads({required int page, required int limit}) async {
    final res = await _dio.post('/loads/get', data: {
      'page': page,
      'limit': limit,
    });
    return PaginatedResponse.fromJson(
      (res.data['data'] ?? res.data) as Map<String, dynamic>,
      (json) => LoadDto.fromJson(json! as Map<String, dynamic>),
    );
  }

  Future<LoadDto> getLoadById(String id) async {
    final res = await _dio.post('/loads/get-load', data: {'load_id': id});
    return LoadDto.fromJson((res.data['data'] ?? res.data) as Map<String, dynamic>);
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
}
