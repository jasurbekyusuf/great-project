import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/features/garage/domain/entities/garage_route.dart';
import 'package:loadme_mobile/features/garage/domain/entities/garage_vehicle.dart';
import 'package:loadme_mobile/features/garage/domain/entities/transport_detail.dart';

/// Garage data contract — the user's vehicles, their saved routes, and the
/// public transport detail shown when a transport/truck is opened.
abstract interface class GarageRepository {
  AsyncResult<List<GarageVehicle>> getVehicles();

  AsyncResult<void> addVehicle(GarageVehicle vehicle);

  AsyncResult<List<GarageRoute>> getRoutes();

  AsyncResult<void> addRoute(GarageRoute route);

  AsyncResult<TransportDetail> getTransportDetail(String id);

  AsyncResult<void> toggleRoute(String id);

  AsyncResult<void> deleteRoute(String id);
}
