import 'package:loadme_mobile/features/garage/domain/entities/garage_route.dart';
import 'package:loadme_mobile/features/garage/domain/entities/garage_vehicle.dart';
import 'package:loadme_mobile/features/garage/domain/entities/transport_detail.dart';

/// Garage data source contract, implemented by `GarageRemoteDataSource` over
/// the real LoadMe truck endpoints (vehicles → `/trucks/`, routes →
/// `/trucks/routes/`).
abstract interface class GarageDataSource {
  Future<List<GarageVehicle>> getVehicles();
  Future<void> addVehicle(GarageVehicle vehicle);
  Future<List<GarageRoute>> getRoutes();
  Future<void> addRoute(GarageRoute route);
  Future<TransportDetail> getTransportDetail(String id);
  Future<void> toggleRoute(String id);
  Future<void> deleteRoute(String id);
}
