import 'package:loadme_mobile/features/trucks/domain/entities/truck_entity.dart';
import 'package:loadme_mobile/features/trucks/domain/entities/truck_detail_entity.dart';

abstract interface class TrucksRepository {
  Future<List<TruckEntity>> getTrucks({required int page, required int limit});
  Future<List<TruckEntity>> getMyPostTrucks({
    required int page,
    required int limit,
    required bool isActive,
  });
  Future<List<TruckEntity>> getMyTrucks(
      {required int page, required int limit});
  Future<TruckDetailEntity> getTruckById(String id);
  Future<void> updatePostTruckStatus({
    required String guid,
    required bool isActive,
  });
  Future<void> updateTruckStatus({
    required String guid,
    required bool isActive,
  });
}
