import 'package:loadme_mobile/core/result/guard.dart';
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/features/magnit/data/datasources/magnit_remote_data_source.dart';
import 'package:loadme_mobile/features/magnit/domain/entities/magnit_activation.dart';
import 'package:loadme_mobile/features/magnit/domain/entities/magnit_truck_type.dart';
import 'package:loadme_mobile/features/magnit/domain/repositories/magnit_repository.dart';

class MagnitRepositoryImpl implements MagnitRepository {
  MagnitRepositoryImpl(this._ds);

  final MagnitRemoteDataSource _ds;
  static const _tag = 'MagnitRepository';

  @override
  AsyncResult<List<MagnitTruckType>> getTruckTypes() =>
      Guard.run(_ds.getTruckTypes, tag: _tag);

  @override
  AsyncResult<List<MagnitTruckType>> getTruckModels() =>
      Guard.run(_ds.getTruckModels, tag: _tag);

  @override
  AsyncResult<MagnitActivation> activate({
    required String truckType,
    String? pickupCountry,
    String? pickupRegion,
    String? pickupDistrict,
    String? deliveryCountry,
    String? deliveryRegion,
    String? deliveryDistrict,
    int? deadheadRadiusKm,
  }) =>
      Guard.run(
        () => _ds.activate(
          truckType: truckType,
          pickupCountry: pickupCountry,
          pickupRegion: pickupRegion,
          pickupDistrict: pickupDistrict,
          deliveryCountry: deliveryCountry,
          deliveryRegion: deliveryRegion,
          deliveryDistrict: deliveryDistrict,
          deadheadRadiusKm: deadheadRadiusKm,
        ),
        tag: _tag,
      );
}
