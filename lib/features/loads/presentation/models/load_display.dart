import 'package:equatable/equatable.dart';
import 'package:loadme_mobile/features/loads/domain/entities/load_entity.dart';

/// View model consumed by the loads cards.
///
/// Backend-agnostic snapshot of everything a card needs to render. The
/// repository (real or fake) returns a list of these so the UI never
/// reaches for inline arrays.
class LoadDisplay extends Equatable {
  const LoadDisplay({
    required this.load,
    required this.ownerName,
    required this.fromCountry,
    required this.toCountry,
    required this.distanceKm,
    required this.deadHeadKm,
    required this.volumeM3,
    required this.weightT,
    required this.priceLabel,
    required this.loadKind,
    required this.truckType,
    this.ownerRating,
    this.roleBadge,
  });

  final LoadEntity load;
  final String ownerName;
  final String fromCountry;
  final String toCountry;
  final int distanceKm;
  final int deadHeadKm;
  final double volumeM3;
  final double weightT;
  final String priceLabel;
  final String loadKind;
  final String truckType;
  final double? ownerRating;
  final String? roleBadge;

  @override
  List<Object?> get props => [
        load.guid,
        ownerName,
        fromCountry,
        toCountry,
        distanceKm,
        deadHeadKm,
        volumeM3,
        weightT,
        priceLabel,
        loadKind,
        truckType,
        ownerRating,
        roleBadge,
      ];
}
