import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/features/loads/domain/entities/load_entity.dart';

abstract interface class LoadsRepository {
  AsyncResult<List<LoadEntity>> getLoads({required int page, required int limit});

  AsyncResult<List<LoadEntity>> getMyLoads({
    required int page,
    required int limit,
    required bool isActive,
    String? userGuid,
  });

  AsyncResult<LoadEntity> getLoadById(String id);

  AsyncResult<void> addLoad({
    required String fromAddress,
    required String toAddress,
    required String comment,
  });

  AsyncResult<void> updateLoad({
    required String loadId,
    required String fromAddress,
    required String toAddress,
    required String comment,
  });

  AsyncResult<void> updateLoadStatus({
    required String guid,
    required bool isActive,
    String? closedPlatform,
  });
}
