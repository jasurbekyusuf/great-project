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

/// Resolves human truck-type labels (the hardcoded Uzbek picker labels used by
/// the search sheet / Filtrlar / load form) to the backend `truck_type` UUIDs
/// the API expects, matching case- and whitespace-insensitively on the name.
/// Unmatched labels are dropped (never sent as raw text the backend rejects),
/// and the result is de-duplicated while preserving the picked order.
List<String> resolveTruckTypeIds(
  List<MagnitTruckType> types,
  Iterable<String> labels,
) {
  String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  final byName = {for (final t in types) norm(t.name): t.id};
  final ids = <String>[];
  for (final label in labels) {
    final id = byName[norm(label)];
    if (id != null && !ids.contains(id)) ids.add(id);
  }
  return ids;
}

/// The truck-model catalogue (`GET /trucks/models/`) — drives the create form's
/// model picker so a picked catalogue entry carries the backend `truck_model`
/// UUID. The list is empty until the backend is seeded, so the picker keeps a
/// static fallback for offline/empty cases.
final truckModelsProvider =
    FutureProvider.autoDispose<List<MagnitTruckType>>((ref) async {
  final result = await ref.watch(magnitRepositoryProvider).getTruckModels();
  return result.fold((f) => throw f, (models) => models);
});
