import 'package:equatable/equatable.dart';
import 'package:loadme_mobile/features/trucks/domain/entities/truck_entity.dart';

/// View model consumed by truck cards.
///
/// Mirrors `LoadDisplay`: a backend-agnostic snapshot the card renders directly.
/// Numeric/date fields are nullable — a missing value hides its chip rather than
/// rendering a misleading zero. The string fields the card requires
/// (`priceLabel`, `loadKind`, `truckType`, countries) stay non-null and are
/// given sensible fallbacks by the display provider.
class TruckDisplay extends Equatable {
  const TruckDisplay({
    required this.truck,
    required this.ownerName,
    required this.fromCountry,
    required this.toCountry,
    required this.priceLabel,
    required this.loadKind,
    required this.truckType,
    this.distanceKm,
    this.volumeM3,
    this.weightT,
    this.pickupDateIso,
    this.ownerRating,
    this.timeAgo,
  });

  final TruckEntity truck;
  final String ownerName;
  final String fromCountry;
  final String toCountry;
  final String priceLabel;
  final String loadKind;
  final String truckType;
  final int? distanceKm;
  final double? volumeM3;
  final double? weightT;
  final String? pickupDateIso;
  final double? ownerRating;
  final String? timeAgo;

  @override
  List<Object?> get props => [
        truck.guid,
        ownerName,
        fromCountry,
        toCountry,
        priceLabel,
        loadKind,
        truckType,
        distanceKm,
        volumeM3,
        weightT,
        pickupDateIso,
        ownerRating,
        timeAgo,
      ];
}
