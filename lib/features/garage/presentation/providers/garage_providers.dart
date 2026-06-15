import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/features/garage/data/datasources/fake_garage_data_source.dart';
import 'package:loadme_mobile/features/garage/data/repositories/garage_repository_impl.dart';
import 'package:loadme_mobile/features/garage/domain/entities/garage_route.dart';
import 'package:loadme_mobile/features/garage/domain/entities/garage_vehicle.dart';
import 'package:loadme_mobile/features/garage/domain/entities/transport_detail.dart';
import 'package:loadme_mobile/features/garage/domain/repositories/garage_repository.dart';

// Re-export the entities so widgets need only one import.
export 'package:loadme_mobile/features/garage/domain/entities/garage_route.dart';
export 'package:loadme_mobile/features/garage/domain/entities/garage_vehicle.dart';
export 'package:loadme_mobile/features/garage/domain/entities/transport_detail.dart';

/// Garage repository. No remote source yet, so always fake — swap in a
/// Dio-backed `GarageDataSource` here (gated on `appEnvProvider.useFakeData`,
/// like `loadsRepositoryProvider`) when the backend lands.
final garageRepositoryProvider = Provider<GarageRepository>((ref) {
  return GarageRepositoryImpl(FakeGarageDataSource());
});

/// Vehicles for the Transportlar tab.
final garageVehiclesProvider =
    FutureProvider.autoDispose<List<GarageVehicle>>((ref) async {
  final result = await ref.watch(garageRepositoryProvider).getVehicles();
  return result.fold((f) => throw f, (vehicles) => vehicles);
});

/// Saved routes for the Yo'nalishlarim tab + active/delete mutations.
final garageRoutesProvider =
    AutoDisposeAsyncNotifierProvider<GarageRoutesController, List<GarageRoute>>(
  GarageRoutesController.new,
);

class GarageRoutesController extends AutoDisposeAsyncNotifier<List<GarageRoute>> {
  GarageRepository get _repo => ref.read(garageRepositoryProvider);

  @override
  Future<List<GarageRoute>> build() async {
    final result = await _repo.getRoutes();
    return result.fold((f) => throw f, (routes) => routes);
  }

  Future<void> toggleActive(String id) async {
    final current = state.valueOrNull ?? const <GarageRoute>[];
    state = AsyncData([
      for (final r in current)
        if (r.id == id) r.copyWith(active: !r.active) else r,
    ]);
    await _repo.toggleRoute(id);
  }

  Future<void> remove(String id) async {
    final current = state.valueOrNull ?? const <GarageRoute>[];
    state = AsyncData([
      for (final r in current)
        if (r.id != id) r,
    ]);
    await _repo.deleteRoute(id);
  }
}

/// Public transport detail by id (used by Garaj cards and the trucks market).
final transportDetailProvider = FutureProvider.family
    .autoDispose<TransportDetail, String>((ref, id) async {
  final result = await ref.watch(garageRepositoryProvider).getTransportDetail(id);
  return result.fold((f) => throw f, (detail) => detail);
});
