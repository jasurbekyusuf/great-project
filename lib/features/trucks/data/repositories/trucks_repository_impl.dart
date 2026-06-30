import 'package:loadme_mobile/core/result/guard.dart';
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/features/trucks/data/datasources/trucks_remote_data_source.dart';
import 'package:loadme_mobile/features/trucks/domain/entities/truck_detail_entity.dart';
import 'package:loadme_mobile/features/trucks/domain/entities/truck_entity.dart';
import 'package:loadme_mobile/features/trucks/domain/repositories/trucks_repository.dart';

/// Thin passthrough: the data source already returns enriched [TruckEntity] /
/// [TruckDetailEntity] objects parsed from the real `/trucks/` payloads, so the
/// repository only wraps each call in a [Guard] to turn exceptions into
/// `AsyncResult` failures.
class TrucksRepositoryImpl implements TrucksRepository {
  TrucksRepositoryImpl(this._remote);
  final TrucksRemoteDataSource _remote;
  static const _tag = 'TrucksRepository';

  static AsyncResult<T> _guard<T>(Future<T> Function() block) =>
      Guard.run(block, tag: _tag);

  @override
  AsyncResult<List<TruckEntity>> getTrucks({
    required int page,
    required int limit,
    Map<String, String>? filters,
  }) =>
      _guard(() => _remote.getTrucks(page: page, limit: limit, filters: filters));

  @override
  AsyncResult<int> getTrucksCount({Map<String, String>? filters}) =>
      _guard(() => _remote.getTrucksCount(filters: filters));

  @override
  AsyncResult<List<TruckEntity>> getMyPostTrucks({
    required int page,
    required int limit,
    required bool isActive,
  }) =>
      _guard(() =>
          _remote.getMyPostTrucks(page: page, limit: limit, isActive: isActive));

  @override
  AsyncResult<List<TruckEntity>> getMyTrucks({required int page, required int limit}) =>
      _guard(() => _remote.getMyTrucks(page: page, limit: limit));

  @override
  AsyncResult<TruckDetailEntity> getTruckById(String id) =>
      _guard(() => _remote.getTruckById(id));

  @override
  AsyncResult<void> updatePostTruckStatus({required String guid, required bool isActive}) =>
      _guard(() => _remote.updatePostTruckStatus(guid: guid, isActive: isActive));

  @override
  AsyncResult<void> updateTruckStatus({required String guid, required bool isActive}) =>
      _guard(() => _remote.updateTruckStatus(guid: guid, isActive: isActive));
}
