/// A posted truck route (free-truck offer) as surfaced by the LoadMe backend.
///
/// Plain immutable class (no codegen): the real `/trucks/routes/` payload nests
/// owner, the vehicle (`truck`), currency and pickup/delivery location objects,
/// so a hand-written mapping in the data source is clearer than generated JSON
/// glue. Display-ready fields (`priceLabel`, `timeAgo`, weight/volume split out
/// of `measurement_*`) are computed once in the data source so the presentation
/// layer stays thin. Mirrors `LoadEntity`.
class TruckEntity {
  const TruckEntity({
    required this.guid,
    required this.fromAddress,
    required this.toAddress,
    this.fromCountry,
    this.toCountry,
    this.note,
    this.price,
    this.priceLabel,
    this.departureDate,
    this.arrivalDate,
    this.createdAt,
    this.timeAgo,
    this.truckType,
    this.weightT,
    this.volumeM3,
    this.distanceKm,
    this.radiusKm,
    this.ownerName,
    this.ownerRating,
    this.roleBadge,
    this.verified = false,
    this.isPartial = false,
    this.isActive = true,
    this.phone,
    this.telegram,
    this.whatsapp,
  });

  final String guid;

  /// Composed "city, region" line for the origin (split by `addressCity`).
  final String fromAddress;
  final String toAddress;

  /// ISO country code (or name) rendered as a pill next to each city.
  final String? fromCountry;
  final String? toCountry;

  final String? note;

  /// Raw numeric price, plus the pre-formatted label ("20 000 000 so'm" or
  /// "Kelishiladi" when there is no price).
  final double? price;
  final String? priceLabel;

  /// ISO timestamps from the backend (`departure_date` / `arrival_date`).
  final String? departureDate;
  final String? arrivalDate;
  final String? createdAt;

  /// Localised "X soat oldin" label derived from [createdAt].
  final String? timeAgo;

  /// Card-title name for the vehicle on this route — the nested `truck` model
  /// or truck-type display name (a bare UUID is left null).
  final String? truckType;

  /// Weight (ton) / volume (m³) split out of `measurement_value` + unit.
  final double? weightT;
  final double? volumeM3;

  final int? distanceKm;

  /// `deadhead_radius_km` — how far the carrier will deviate to pick up.
  final int? radiusKm;

  final String? ownerName;
  final double? ownerRating;

  /// Display badge: "Yuk egasi" | "Logist" | "LoadMe AI".
  final String? roleBadge;
  final bool verified;

  /// `is_partial` → "Qisman" vs "To'liq".
  final bool isPartial;
  final bool isActive;

  final String? phone;
  final String? telegram;
  final String? whatsapp;
}
