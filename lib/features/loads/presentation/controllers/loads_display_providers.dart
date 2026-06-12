import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/features/loads/data/datasources/fake_loads_remote_data_source.dart';
import 'package:loadme_mobile/features/loads/domain/entities/load_entity.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_controller.dart';
import 'package:loadme_mobile/features/loads/presentation/models/load_display.dart';

/// Pure transform from raw `LoadEntity` list to `LoadDisplay` view models.
///
/// All "look real" data (varied prices, owner names, country codes) lives
/// in the data layer (see [FakeLoadsRemoteDataSource]) — the UI consumes
/// only [LoadDisplay] objects and never reaches for inline arrays.
final loadsDisplayProvider = Provider<AsyncValue<List<LoadDisplay>>>((ref) {
  return ref.watch(loadsControllerProvider).whenData(_toDisplayList);
});

final myLoadsDisplayProvider = Provider<AsyncValue<List<LoadDisplay>>>((ref) {
  return ref.watch(myLoadsControllerProvider).whenData(_toDisplayList);
});

List<LoadDisplay> _toDisplayList(List<LoadEntity> items) =>
    [for (var i = 0; i < items.length; i++) _toDisplay(i, items[i])];

LoadDisplay _toDisplay(int index, LoadEntity load) {
  final countries = FakeLoadsRemoteDataSource.countriesForIndex(index);
  return LoadDisplay(
    load: load,
    ownerName: FakeLoadsRemoteDataSource.ownerNameForIndex(index),
    fromCountry: countries.$1,
    toCountry: countries.$2,
    distanceKm: 328 + index * 61,
    deadHeadKm: 10 + index * 5,
    volumeM3: 20.0 + index * 4,
    weightT: 33.0 - index * 2,
    priceLabel: FakeLoadsRemoteDataSource.priceLabelForIndex(index),
    loadKind: "To'liq",
    truckType: FakeLoadsRemoteDataSource.truckTypeForIndex(index),
    ownerRating: 4.5,
    roleBadge: FakeLoadsRemoteDataSource.roleBadgeForIndex(index),
    verified: FakeLoadsRemoteDataSource.verifiedForIndex(index),
    radiusKm: FakeLoadsRemoteDataSource.radiusForIndex(index),
    timeAgo: FakeLoadsRemoteDataSource.timeAgoForIndex(index),
  );
}
