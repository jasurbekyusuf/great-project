import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/features/magnit/domain/entities/magnit_activation.dart';
import 'package:loadme_mobile/features/magnit/domain/entities/magnit_truck_type.dart';

/// Magnit (auto truck-route alert) backend contract.
abstract class MagnitRepository {
  /// The truck-type directory (`GET /trucks/types/`) backing the picker.
  AsyncResult<List<MagnitTruckType>> getTruckTypes();

  /// The truck-model catalogue (`GET /trucks/models/`) backing the create
  /// form's model picker; each entry carries the `truck_model` UUID.
  AsyncResult<List<MagnitTruckType>> getTruckModels();

  /// Activates a magnet (`POST /trucks/routes/magnet/`). Only [truckType] is
  /// mandatory; the pickup/delivery ids are sent under whichever filter key the
  /// picked location resolves to (`country` / `region` / `district`).
  AsyncResult<MagnitActivation> activate({
    required String truckType,
    String? pickupCountry,
    String? pickupRegion,
    String? pickupDistrict,
    String? deliveryCountry,
    String? deliveryRegion,
    String? deliveryDistrict,
    int? deadheadRadiusKm,
  });
}
