import 'package:loadme_mobile/features/loads/domain/entities/load_entity.dart';

abstract interface class LoadsRepository {
  Future<List<LoadEntity>> getLoads({required int page, required int limit});
  Future<List<LoadEntity>> getMyLoads({
    required int page,
    required int limit,
    required bool isActive,
    String? userGuid,
  });
  Future<LoadEntity> getLoadById(String id);
  Future<void> addLoad({
    required String fromAddress,
    required String toAddress,
    required String comment,
  });
  Future<void> updateLoad({
    required String loadId,
    required String fromAddress,
    required String toAddress,
    required String comment,
  });
  Future<void> updateLoadStatus({
    required String guid,
    required bool isActive,
    String? closedPlatform,
  });
}
