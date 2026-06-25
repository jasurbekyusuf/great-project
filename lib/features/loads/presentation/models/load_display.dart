import 'package:equatable/equatable.dart';
import 'package:loadme_mobile/features/loads/domain/entities/load_entity.dart';

/// View model consumed by the loads cards.
///
/// Backend-agnostic snapshot of everything a card needs to render. The display
/// provider builds these from an enriched [LoadEntity] so the UI never reaches
/// for inline arrays. Numeric/price fields are nullable: a missing value hides
/// its chip rather than rendering a misleading zero.
class LoadDisplay extends Equatable {
  const LoadDisplay({
    required this.load,
    required this.ownerName,
    required this.fromCountry,
    required this.toCountry,
    required this.loadKind,
    required this.truckType,
    this.distanceKm,
    this.deadHeadKm,
    this.volumeM3,
    this.weightT,
    this.priceLabel,
    this.ownerRating,
    this.roleBadge,
    this.verified = false,
    this.radiusKm,
    this.timeAgo,
  });

  final LoadEntity load;
  final String ownerName;
  final String fromCountry;
  final String toCountry;
  final String loadKind;
  final String truckType;
  final int? distanceKm;
  final int? deadHeadKm;
  final double? volumeM3;
  final double? weightT;
  final String? priceLabel;
  final double? ownerRating;
  final String? roleBadge;
  final bool verified;
  final int? radiusKm;
  final String? timeAgo;

  @override
  List<Object?> get props => [
        load.guid,
        ownerName,
        fromCountry,
        toCountry,
        loadKind,
        truckType,
        distanceKm,
        deadHeadKm,
        volumeM3,
        weightT,
        priceLabel,
        ownerRating,
        roleBadge,
        verified,
        radiusKm,
        timeAgo,
      ];
}
