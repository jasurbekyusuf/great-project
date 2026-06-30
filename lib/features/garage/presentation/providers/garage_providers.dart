import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/network/dio_client.dart';
import 'package:loadme_mobile/features/garage/data/datasources/garage_remote_data_source.dart';
import 'package:loadme_mobile/features/garage/data/repositories/garage_repository_impl.dart';
import 'package:loadme_mobile/features/garage/domain/entities/garage_route.dart';
import 'package:loadme_mobile/features/garage/domain/entities/garage_vehicle.dart';
import 'package:loadme_mobile/features/garage/domain/entities/transport_detail.dart';
import 'package:loadme_mobile/features/garage/domain/repositories/garage_repository.dart';
import 'package:loadme_mobile/features/magnit/presentation/providers/magnit_providers.dart';

// Re-export the entities so widgets need only one import.
export 'package:loadme_mobile/features/garage/domain/entities/garage_route.dart';
export 'package:loadme_mobile/features/garage/domain/entities/garage_vehicle.dart';
export 'package:loadme_mobile/features/garage/domain/entities/transport_detail.dart';

/// Garage repository, backed by the real LoadMe truck endpoints
/// (`GarageRemoteDataSource` over the shared [dioProvider], which already
/// targets the active local/prod environment).
final garageRepositoryProvider = Provider<GarageRepository>((ref) {
  return GarageRepositoryImpl(GarageRemoteDataSource(ref.watch(dioProvider)));
});

/// Vehicles for the Transportlar tab.
///
/// The `/trucks/` list often carries the truck type as a bare UUID, so the
/// data source leaves the type name empty. Those are resolved here against the
/// truck-types directory so the "Transport turi" chip shows right after a truck
/// is added; the model is used as a last-resort fallback.
final garageVehiclesProvider =
    FutureProvider.autoDispose<List<GarageVehicle>>((ref) async {
  final result = await ref.watch(garageRepositoryProvider).getVehicles();
  final vehicles = result.fold((f) => throw f, (v) => v);

  if (vehicles.every((v) => v.name.isNotEmpty)) return vehicles;

  var byId = const <String, String>{};
  try {
    final types = await ref.watch(truckTypesProvider.future);
    byId = {for (final t in types) t.id: t.name};
  } catch (_) {
    // Types directory unavailable — fall back to the model below.
  }

  return [
    for (final v in vehicles)
      v.name.isNotEmpty
          ? v
          : v.copyWith(
              name: (v.truckTypeId == null ? null : byId[v.truckTypeId]) ??
                  (v.model.isNotEmpty ? v.model : '—'),
            ),
  ];
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
