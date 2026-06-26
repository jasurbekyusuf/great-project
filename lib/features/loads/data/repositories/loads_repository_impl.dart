import 'package:loadme_mobile/core/result/guard.dart';
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/features/loads/data/datasources/loads_remote_data_source.dart';
import 'package:loadme_mobile/features/loads/domain/entities/load_entity.dart';
import 'package:loadme_mobile/features/loads/domain/repositories/loads_repository.dart';

class LoadsRepositoryImpl implements LoadsRepository {
  LoadsRepositoryImpl(this._remote);

  final LoadsRemoteDataSource _remote;
  static const _tag = 'LoadsRepository';

  static AsyncResult<T> _guard<T>(Future<T> Function() block) =>
      Guard.run(block, tag: _tag);

  @override
  AsyncResult<List<LoadEntity>> getLoads({
    required int page,
    required int limit,
    Map<String, String>? filters,
  }) =>
      _guard(
          () => _remote.getLoads(page: page, limit: limit, filters: filters));

  @override
  AsyncResult<int> getLoadsCount({Map<String, String>? filters}) =>
      _guard(() => _remote.getLoadsCount(filters: filters));

  @override
  AsyncResult<List<LoadEntity>> getMyLoads({
    required int page,
    required int limit,
    required bool isActive,
    String? userGuid,
  }) =>
      _guard(() => _remote.getUserLoads(
            page: page,
            limit: limit,
            isActive: isActive,
            userGuid: userGuid,
          ));

  @override
  AsyncResult<LoadEntity> getLoadById(String id) =>
      _guard(() => _remote.getLoadById(id));

  @override
  AsyncResult<void> addLoad({
    required String fromAddress,
    required String toAddress,
    required String comment,
  }) =>
      _guard(() => _remote.addLoad(
            fromAddress: fromAddress,
            toAddress: toAddress,
            comment: comment,
          ));

  @override
  AsyncResult<void> updateLoad({
    required String loadId,
    required String fromAddress,
    required String toAddress,
    required String comment,
  }) =>
      _guard(() => _remote.updateLoad(
            loadId: loadId,
            fromAddress: fromAddress,
            toAddress: toAddress,
            comment: comment,
          ));

  @override
  AsyncResult<void> updateLoadStatus({
    required String guid,
    required bool isActive,
    String? closedPlatform,
  }) =>
      _guard(() => _remote.updateLoadStatus(
            guid: guid,
            isActive: isActive,
            closedPlatform: closedPlatform,
          ));
}
