import 'package:loadme_mobile/features/trucks/domain/entities/truck_entity.dart';

abstract interface class TrucksRepository {
  Future<List<TruckEntity>> getTrucks({required int page, required int limit});
}
