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
  return ref.watch(trucksControllerProvider).whenData(_toDisplayList);
});

final myTrucksDisplayProvider = Provider<AsyncValue<List<TruckDisplay>>>((ref) {
  return ref.watch(myTrucksControllerProvider).whenData(_toDisplayList);
});

List<TruckDisplay> _toDisplayList(List<TruckEntity> items) =>
    [for (var i = 0; i < items.length; i++) _toDisplay(i, items[i])];

// Truck model names shown as the card title (Figma "Isuzu Katta" etc.).
const _truckModels = [
  'Isuzu Katta',
  'MAN TGX',
  'Mercedes Actros',
  'Kamaz 5490',
  'Isuzu Katta',
  'Volvo FH',
  'Scania R500',
  'Howo Sino',
];

TruckDisplay _toDisplay(int index, TruckEntity truck) {
  final countries = FakeLoadsRemoteDataSource.countriesForIndex(index);
  final base = DateTime(2026, 5, 28 + (index % 5));
  return TruckDisplay(
    truck: truck,
    ownerName: FakeLoadsRemoteDataSource.ownerNameForIndex(index),
    fromCountry: countries.$1,
    toCountry: countries.$2,
    distanceKm: 328 + index * 61,
    volumeM3: 20.0 + index * 4,
    weightT: 33.0 - index * 2,
    priceLabel: FakeLoadsRemoteDataSource.priceLabelForIndex(index),
    loadKind: "To'liq",
    truckType: _truckModels[index % _truckModels.length],
    pickupDateIso: base.toIso8601String(),
    timeAgo: FakeLoadsRemoteDataSource.timeAgoForIndex(index),
  );
}
