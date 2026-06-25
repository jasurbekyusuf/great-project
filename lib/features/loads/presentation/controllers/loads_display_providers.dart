import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/features/loads/domain/entities/load_entity.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_controller.dart';
import 'package:loadme_mobile/features/loads/presentation/models/load_display.dart';

/// Pure transform from the enriched `LoadEntity` list to `LoadDisplay` view
/// models. Every value now comes from the real backend payload — the data
/// source pre-computes the display-ready bits (price label, time-ago, weight /
/// volume), so this is a thin field-for-field projection.
final loadsDisplayProvider = Provider<AsyncValue<List<LoadDisplay>>>((ref) {
  return ref.watch(loadsControllerProvider).whenData(_toDisplayList);
});

final myLoadsDisplayProvider = Provider<AsyncValue<List<LoadDisplay>>>((ref) {
  return ref.watch(myLoadsControllerProvider).whenData(_toDisplayList);
});

List<LoadDisplay> _toDisplayList(List<LoadEntity> items) =>
    items.map(_toDisplay).toList();

LoadDisplay _toDisplay(LoadEntity load) {
  return LoadDisplay(
    load: load,
    ownerName: load.ownerName ?? 'LoadMe',
    fromCountry: load.fromCountry ?? '',
    toCountry: load.toCountry ?? '',
    loadKind: load.isPartial ? 'Qisman' : "To'liq",
    truckType: load.truckType ?? '—',
    distanceKm: load.distanceKm,
    deadHeadKm: load.radiusKm,
    volumeM3: load.volumeM3,
    weightT: load.weightT,
    priceLabel: load.priceLabel,
    ownerRating: load.ownerRating,
    roleBadge: load.roleBadge,
    verified: load.verified,
    radiusKm: load.radiusKm,
    timeAgo: load.timeAgo,
  );
}
