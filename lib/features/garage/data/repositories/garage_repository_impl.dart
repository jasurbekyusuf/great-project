import 'package:loadme_mobile/core/result/guard.dart';
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/features/garage/data/datasources/garage_data_source.dart';
import 'package:loadme_mobile/features/garage/domain/entities/garage_route.dart';
import 'package:loadme_mobile/features/garage/domain/entities/garage_vehicle.dart';
import 'package:loadme_mobile/features/garage/domain/entities/transport_detail.dart';
import 'package:loadme_mobile/features/garage/domain/repositories/garage_repository.dart';

class GarageRepositoryImpl implements GarageRepository {
  GarageRepositoryImpl(this._ds);

  final GarageDataSource _ds;
  static const _tag = 'GarageRepository';

  static AsyncResult<T> _guard<T>(Future<T> Function() block) =>
      Guard.run(block, tag: _tag);

  @override
  AsyncResult<List<GarageVehicle>> getVehicles() => _guard(_ds.getVehicles);

  @override
  AsyncResult<void> addVehicle(GarageVehicle vehicle) =>
      _guard(() => _ds.addVehicle(vehicle));

  @override
  AsyncResult<List<GarageRoute>> getRoutes() => _guard(_ds.getRoutes);

  @override
  AsyncResult<void> addRoute(GarageRoute route) =>
      _guard(() => _ds.addRoute(route));

  @override
  AsyncResult<TransportDetail> getTransportDetail(String id) =>
      _guard(() => _ds.getTransportDetail(id));

  @override
  AsyncResult<void> toggleRoute(String id) => _guard(() => _ds.toggleRoute(id));

  @override
  AsyncResult<void> deleteRoute(String id) => _guard(() => _ds.deleteRoute(id));
}
