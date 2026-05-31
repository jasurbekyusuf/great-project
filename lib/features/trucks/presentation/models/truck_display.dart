import 'package:equatable/equatable.dart';
import 'package:loadme_mobile/features/trucks/domain/entities/truck_entity.dart';

/// View model consumed by truck cards.
///
/// Mirrors `LoadDisplay`: keeps the UI free of inline fake-data arrays.
/// Backend-agnostic shape — the data layer hydrates these.
class TruckDisplay extends Equatable {
  const TruckDisplay({
    required this.truck,
    required this.ownerName,
    required this.fromCountry,
    required this.toCountry,
    required this.distanceKm,
    required this.volumeM3,
    required this.weightT,
    required this.priceLabel,
    required this.loadKind,
    required this.truckType,
    required this.pickupDateIso,
    this.ownerRating,
  });

  final TruckEntity truck;
  final String ownerName;
  final String fromCountry;
  final String toCountry;
  final int distanceKm;
  final double volumeM3;
  final double weightT;
  final String priceLabel;
  final String loadKind;
  final String truckType;
  final String pickupDateIso;
  final double? ownerRating;

  @override
  List<Object?> get props => [
        truck.guid,
        ownerName,
        fromCountry,
        toCountry,
        distanceKm,
        volumeM3,
        weightT,
        priceLabel,
        loadKind,
        truckType,
        pickupDateIso,
        ownerRating,
      ];
}
