import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/network/dio_client.dart';
import 'package:loadme_mobile/features/magnit/data/datasources/magnit_remote_data_source.dart';
import 'package:loadme_mobile/features/magnit/data/repositories/magnit_repository_impl.dart';
import 'package:loadme_mobile/features/magnit/domain/entities/magnit_truck_type.dart';
import 'package:loadme_mobile/features/magnit/domain/repositories/magnit_repository.dart';

// Re-export the entities so the screen needs only this one import.
export 'package:loadme_mobile/features/magnit/domain/entities/magnit_activation.dart';
export 'package:loadme_mobile/features/magnit/domain/entities/magnit_truck_type.dart';

/// Magnit repository, backed by the real LoadMe truck endpoints over the shared
/// [dioProvider].
final magnitRepositoryProvider = Provider<MagnitRepository>((ref) {
  return MagnitRepositoryImpl(MagnitRemoteDataSource(ref.watch(dioProvider)));
});

/// The truck-type directory (`GET /trucks/types/`) — drives the Magnit
/// transport picker so each pick carries the backend `truck_type` UUID.
final truckTypesProvider =
    FutureProvider.autoDispose<List<MagnitTruckType>>((ref) async {
  final result = await ref.watch(magnitRepositoryProvider).getTruckTypes();
  return result.fold((f) => throw f, (types) => types);
});

/// The truck-model catalogue (`GET /trucks/models/`) — drives the create form's
/// model picker so a picked catalogue entry carries the backend `truck_model`
/// UUID. The list is empty until the backend is seeded, so the picker keeps a
/// static fallback for offline/empty cases.
final truckModelsProvider =
    FutureProvider.autoDispose<List<MagnitTruckType>>((ref) async {
  final result = await ref.watch(magnitRepositoryProvider).getTruckModels();
  return result.fold((f) => throw f, (models) => models);
});
