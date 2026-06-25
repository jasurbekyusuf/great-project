import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/network/dio_client.dart';
import 'package:loadme_mobile/features/locations/data/datasources/locations_remote_data_source.dart';
import 'package:loadme_mobile/features/locations/data/repositories/locations_repository_impl.dart';
import 'package:loadme_mobile/features/locations/domain/entities/location_entity.dart';
import 'package:loadme_mobile/features/locations/domain/repositories/locations_repository.dart';

final locationsRepositoryProvider = Provider<LocationsRepository>(
  (ref) => LocationsRepositoryImpl(
      LocationsRemoteDataSource(ref.watch(dioProvider))),
);

/// Debounced location autocomplete for the "Qayerdan / Qayerga" search.
///
/// Keyed by the raw query string: each distinct query is its own
/// auto-disposed request that fires 300 ms after typing settles, so a burst of
/// keystrokes makes at most one network call (the intermediate keys are
/// disposed during their debounce window and bail out before hitting the API).
final locationSearchProvider = FutureProvider.family
    .autoDispose<List<LocationEntity>, String>((ref, query) async {
  final q = query.trim();
  if (q.isEmpty) return const <LocationEntity>[];

  // Debounce: if the user keeps typing, this key is disposed during the wait —
  // skip the call rather than racing a result the UI no longer wants.
  var active = true;
  ref.onDispose(() => active = false);
  await Future<void>.delayed(const Duration(milliseconds: 300));
  if (!active) return const <LocationEntity>[];

  final result = await ref.read(locationsRepositoryProvider).search(q);
  return result.fold((f) => throw f, (list) => list);
});
