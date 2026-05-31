import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/features/loads/data/datasources/fake_loads_remote_data_source.dart';
import 'package:loadme_mobile/features/trucks/domain/entities/truck_entity.dart';
import 'package:loadme_mobile/features/trucks/presentation/controllers/trucks_controller.dart';
import 'package:loadme_mobile/features/trucks/presentation/models/truck_display.dart';

/// Pure transform from raw `TruckEntity` list to `TruckDisplay` view models.
///
/// All "look real" data (names, countries, prices) lives in the data layer
/// helpers — the UI consumes only [TruckDisplay] objects.
final trucksDisplayProvider = Provider<AsyncValue<List<TruckDisplay>>>((ref) {
  final trucks = ref.watch(trucksControllerProvider);
  return trucks.whenData(
    (items) => items
        .asMap()
        .entries
        .map((e) => _toDisplay(e.key, e.value))
        .toList(growable: false),
  );
});

final myTrucksDisplayProvider = Provider<AsyncValue<List<TruckDisplay>>>((ref) {
  final trucks = ref.watch(myTrucksControllerProvider);
  return trucks.whenData(
    (items) => items
        .asMap()
        .entries
        .map((e) => _toDisplay(e.key, e.value))
        .toList(growable: false),
  );
});

TruckDisplay _toDisplay(int index, TruckEntity truck) {
  final countries = FakeLoadsRemoteDataSource.countriesForIndex(index);
  final base = DateTime(2026, 5, 28 + (index % 5));
  return TruckDisplay(
    truck: truck,
    ownerName: FakeLoadsRemoteDataSource.ownerNameForIndex(index),
    fromCountry: countries.$1,
    toCountry: countries.$2,
    distanceKm: 11 + index * 250,
    volumeM3: 4.0 + index * 8,
    weightT: 2.5 + index * 1.5,
    priceLabel: FakeLoadsRemoteDataSource.priceLabelForIndex(index),
    loadKind: "To'liq",
    truckType: index.isEven ? 'Tent / Shtora' : 'Isuzu NQR / NPR',
    pickupDateIso: base.toIso8601String(),
  );
}
