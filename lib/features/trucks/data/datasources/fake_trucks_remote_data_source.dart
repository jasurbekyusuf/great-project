import 'package:dio/dio.dart';
import 'package:loadme_mobile/features/trucks/data/datasources/trucks_remote_data_source.dart';
import 'package:loadme_mobile/features/trucks/data/dtos/truck_dto.dart';
import 'package:loadme_mobile/shared/models/paginated_response.dart';

class FakeTrucksRemoteDataSource extends TrucksRemoteDataSource {
  FakeTrucksRemoteDataSource() : super(Dio());

  static final _sample = List.generate(
    6,
    (i) => TruckDto(
      guid: 'fake-truck-$i',
      fromAddress: _from[i % _from.length],
      toAddress: _to[i % _to.length],
    ),
  );

  static const _from = ['Ташкент', 'Самарканд', 'Фергана'];
  static const _to = ['Бухара', 'Нукус', 'Хива'];

  @override
  Future<PaginatedResponse<TruckDto>> getTrucks({required int page, required int limit}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return PaginatedResponse(count: _sample.length, result: _sample);
  }

  @override
  Future<PaginatedResponse<TruckDto>> getMyPostTrucks({
    required int page,
    required int limit,
    required bool isActive,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final filtered = _sample.take(isActive ? 4 : 2).toList();
    return PaginatedResponse(count: filtered.length, result: filtered);
  }

  @override
  Future<PaginatedResponse<TruckDto>> getMyTrucks({required int page, required int limit}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return PaginatedResponse(count: _sample.length, result: _sample);
  }

  @override
  Future<Map<String, dynamic>> getTruckById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return {
      'guid': id,
      'model': 'MAN TGX',
      'truck_type': 'Тент',
      'capacity': 20,
      'weight': 18000,
      'plate_number': '01 A 123 BB',
      'trailer_number': '01 B 456 CC',
      'phone': '+998900000000',
    };
  }

  @override
  Future<void> updatePostTruckStatus({required String guid, required bool isActive}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> updateTruckStatus({required String guid, required bool isActive}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}
