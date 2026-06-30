import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/features/loads/domain/entities/load_draft.dart';
import 'package:loadme_mobile/features/loads/domain/entities/load_entity.dart';

abstract interface class LoadsRepository {
  AsyncResult<List<LoadEntity>> getLoads({
    required int page,
    required int limit,
    Map<String, String>? filters,
  });

  /// Total number of public loads (the marketplace header count). With
  /// [filters] it returns the *filtered* total — the "Topildi: N" search header.
  AsyncResult<int> getLoadsCount({Map<String, String>? filters});

  AsyncResult<List<LoadEntity>> getMyLoads({
    required int page,
    required int limit,
    required bool isActive,
    String? userGuid,
  });

  AsyncResult<LoadEntity> getLoadById(String id);

  AsyncResult<void> addLoad(LoadDraft draft);

  AsyncResult<void> updateLoad(String loadId, LoadDraft draft);

  AsyncResult<void> updateLoadStatus({
    required String guid,
    required bool isActive,
    String? closedPlatform,
  });
}
