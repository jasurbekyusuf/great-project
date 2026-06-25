import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/features/trucks/domain/entities/truck_entity.dart';
import 'package:loadme_mobile/features/trucks/presentation/controllers/trucks_controller.dart';
import 'package:loadme_mobile/features/trucks/presentation/models/truck_display.dart';

/// Pure transform from the enriched `TruckEntity` list to `TruckDisplay` view
/// models. Every value now comes from the real `/trucks/routes/` payload — the
/// data source pre-computes the display-ready bits (price label, time-ago,
/// weight / volume, truck name), so this is a thin field-for-field projection.
final trucksDisplayProvider = Provider<AsyncValue<List<TruckDisplay>>>((ref) {
  return ref.watch(trucksControllerProvider).whenData(_toDisplayList);
});

final myTrucksDisplayProvider = Provider<AsyncValue<List<TruckDisplay>>>((ref) {
  return ref.watch(myTrucksControllerProvider).whenData(_toDisplayList);
});

List<TruckDisplay> _toDisplayList(List<TruckEntity> items) =>
    items.map(_toDisplay).toList();

TruckDisplay _toDisplay(TruckEntity truck) {
  return TruckDisplay(
    truck: truck,
    ownerName: truck.ownerName ?? 'LoadMe',
    fromCountry: truck.fromCountry ?? '',
    toCountry: truck.toCountry ?? '',
    priceLabel: truck.priceLabel ?? 'Kelishiladi',
    loadKind: truck.isPartial ? 'Qisman' : "To'liq",
    truckType: truck.truckType ?? '—',
    distanceKm: truck.distanceKm,
    volumeM3: truck.volumeM3,
    weightT: truck.weightT,
    pickupDateIso: truck.departureDate,
    ownerRating: truck.ownerRating,
    timeAgo: truck.timeAgo,
  );
}
