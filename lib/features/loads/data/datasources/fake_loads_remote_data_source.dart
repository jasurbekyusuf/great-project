import 'package:dio/dio.dart';
import 'package:loadme_mobile/features/loads/data/datasources/loads_remote_data_source.dart';
import 'package:loadme_mobile/features/loads/data/dtos/load_dto.dart';
import 'package:loadme_mobile/shared/models/paginated_response.dart';

class FakeLoadsRemoteDataSource extends LoadsRemoteDataSource {
  FakeLoadsRemoteDataSource() : super(Dio());

  static final _sample = List.generate(
    8,
    (i) => LoadDto(
      guid: 'fake-load-$i',
      fromAddress: _from[i % _from.length],
      toAddress: _to[i % _to.length],
      comment: 'Тент · ${(i + 1) * 5} т',
      price: 1500000 + i * 250000,
      pickupDate: '2026-06-${(i % 28) + 1}',
    ),
  );

  static const _from = ['Ташкент', 'Самарканд', 'Бухара', 'Наманган'];
  static const _to = ['Самарканд', 'Хива', 'Андижан', 'Нукус'];

  @override
  Future<PaginatedResponse<LoadDto>> getLoads({required int page, required int limit}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return PaginatedResponse(count: _sample.length, result: _sample);
  }

  @override
  Future<PaginatedResponse<LoadDto>> getUserLoads({
    required int page,
    required int limit,
    required bool isActive,
    String? userGuid,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final filtered = _sample.take(isActive ? 5 : 3).toList();
    return PaginatedResponse(count: filtered.length, result: filtered);
  }

  @override
  Future<LoadDto> getLoadById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _sample.firstWhere(
      (e) => e.guid == id,
      orElse: () => _sample.first,
    );
  }

  @override
  Future<void> addLoad({required String fromAddress, required String toAddress, required String comment}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> updateLoad({
    required String loadId,
    required String fromAddress,
    required String toAddress,
    required String comment,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> updateLoadStatus({required String guid, required bool isActive, String? closedPlatform}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}
