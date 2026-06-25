import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/features/trucks/domain/entities/truck_detail_entity.dart';
import 'package:loadme_mobile/features/trucks/domain/entities/truck_entity.dart';

abstract interface class TrucksRepository {
  AsyncResult<List<TruckEntity>> getTrucks({required int page, required int limit});

  /// Total number of public truck routes (the marketplace header count).
  AsyncResult<int> getTrucksCount();

  AsyncResult<List<TruckEntity>> getMyPostTrucks({
    required int page,
    required int limit,
    required bool isActive,
  });

  AsyncResult<List<TruckEntity>> getMyTrucks({required int page, required int limit});

  AsyncResult<TruckDetailEntity> getTruckById(String id);

  AsyncResult<void> updatePostTruckStatus({required String guid, required bool isActive});

  AsyncResult<void> updateTruckStatus({required String guid, required bool isActive});
}
