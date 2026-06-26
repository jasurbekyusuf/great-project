import 'package:loadme_mobile/core/result/guard.dart';
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/features/saved/data/datasources/saved_remote_data_source.dart';
import 'package:loadme_mobile/features/saved/domain/entities/saved_load.dart';
import 'package:loadme_mobile/features/saved/domain/repositories/saved_repository.dart';

class SavedRepositoryImpl implements SavedRepository {
  SavedRepositoryImpl(this._ds);

  final SavedRemoteDataSource _ds;
  static const _tag = 'SavedRepository';

  static AsyncResult<T> _guard<T>(Future<T> Function() block) =>
      Guard.run(block, tag: _tag);

  @override
  AsyncResult<List<SavedLoad>> getSaved() => _guard(_ds.getSaved);

  @override
  AsyncResult<String?> addSaved(String loadId) =>
      _guard(() => _ds.addSaved(loadId));

  @override
  AsyncResult<void> removeSaved(String loadId) =>
      _guard(() => _ds.removeSaved(loadId));

  @override
  AsyncResult<Set<String>> getSavedRouteIds() => _guard(_ds.getSavedRouteIds);

  @override
  AsyncResult<void> addSavedRoute(String routeId) =>
      _guard(() => _ds.addSavedRoute(routeId));

  @override
  AsyncResult<void> removeSavedRoute(String routeId) =>
      _guard(() => _ds.removeSavedRoute(routeId));
}
