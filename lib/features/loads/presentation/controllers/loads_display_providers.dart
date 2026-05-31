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
  final loads = ref.watch(loadsControllerProvider);
  return loads.whenData(
    (items) => items
        .asMap()
        .entries
        .map((e) => _toDisplay(e.key, e.value))
        .toList(growable: false),
  );
});

final myLoadsDisplayProvider = Provider<AsyncValue<List<LoadDisplay>>>((ref) {
  final loads = ref.watch(myLoadsControllerProvider);
  return loads.whenData(
    (items) => items
        .asMap()
        .entries
        .map((e) => _toDisplay(e.key, e.value))
        .toList(growable: false),
  );
});

LoadDisplay _toDisplay(int index, LoadEntity load) {
  final countries = FakeLoadsRemoteDataSource.countriesForIndex(index);
  return LoadDisplay(
    load: load,
    ownerName: FakeLoadsRemoteDataSource.ownerNameForIndex(index),
    fromCountry: countries.$1,
    toCountry: countries.$2,
    distanceKm: 11 + index * 250,
    deadHeadKm: 10 + index * 5,
    volumeM3: 4.0 + index * 8,
    weightT: 2.5 + index * 1.5,
    priceLabel: FakeLoadsRemoteDataSource.priceLabelForIndex(index),
    loadKind: "To'liq",
    truckType: index.isEven ? 'Tent / Shtora' : 'Isuzu NQR / NPR',
    ownerRating: index == 3 ? 5.0 : null,
  );
}
