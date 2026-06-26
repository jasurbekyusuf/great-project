/// A load (cargo offer) as surfaced by the LoadMe backend.
///
/// Plain immutable class (no codegen): the real `/loads/` payload nests owner,
/// currency and pickup/delivery location objects, so a hand-written mapping in
/// the data source is clearer than generated JSON glue. Display-ready fields
/// (`priceLabel`, `timeAgo`, weight/volume split out of `measurement_*`) are
/// computed once in the data source so the presentation layer stays thin.
class LoadEntity {
  const LoadEntity({
    required this.guid,
    required this.fromAddress,
    required this.toAddress,
    this.fromCountry,
    this.toCountry,
    this.comment,
    this.price,
    this.priceLabel,
    this.pickupDate,
    this.deliveryDate,
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
    this.pickupLat,
    this.pickupLng,
    this.deliveryLat,
    this.deliveryLng,
  });

  final String guid;

  /// Composed "city, region" line for the origin (split by `addressCity`).
  final String fromAddress;
  final String toAddress;

  /// ISO country code (or name) rendered as a pill next to each city.
  final String? fromCountry;
  final String? toCountry;

  final String? comment;

  /// Raw numeric price, plus the pre-formatted label ("20 000 000 so'm" or
  /// "Kelishiladi" when there is no price).
  final double? price;
  final String? priceLabel;

  /// ISO timestamps from the backend (`pickup_date` / `delivery_date`).
  final String? pickupDate;
  final String? deliveryDate;
  final String? createdAt;

  /// Localised "X soat oldin" label derived from [createdAt].
  final String? timeAgo;

  /// Truck-type display name when the backend sends an object (a bare UUID is
  /// left null because it cannot be resolved without the types directory).
  final String? truckType;

  /// Weight (ton) / volume (m³) split out of `measurement_value` + unit.
  final double? weightT;
  final double? volumeM3;

  final int? distanceKm;
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

  /// Pickup / delivery coordinates for the route preview. Null when the backend
  /// omits them (the map then falls back to a city-name lookup).
  final double? pickupLat;
  final double? pickupLng;
  final double? deliveryLat;
  final double? deliveryLng;
}
