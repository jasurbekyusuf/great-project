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
    this.commodity,
    this.price,
    this.priceLabel,
    this.advanceLabel,
    this.pickupDate,
    this.deliveryDate,
    this.createdAt,
    this.timeAgo,
    this.truckType,
    this.weightT,
    this.volumeM3,
    this.distanceKm,
    this.radiusKm,
    this.ownerId,
    this.ownerName,
    this.ownerRating,
    this.roleBadge,
    this.verified = false,
    this.isPartial = false,
    this.isActive = true,
    this.isFavorite = false,
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

  /// Commodity / product being shipped (`commodity` on the load payload) —
  /// rendered as the "Mahsulot" detail row. Null when the backend omits it.
  final String? commodity;

  /// Raw numeric price, plus the pre-formatted label ("20 000 000 so'm" or
  /// "Kelishiladi" when there is no price).
  final double? price;
  final String? priceLabel;

  /// Pre-formatted advance/prepayment label ("30 000 000 so'm") from
  /// `advance_payment`; null when there is no advance — the route card's
  /// "Avans" column then shows a dash.
  final String? advanceLabel;

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

  /// Owner's user UUID (`owner.id`) — the `to_user` target when rating or
  /// reporting the load owner from the detail screen. Null when the backend
  /// omits the nested owner object.
  final String? ownerId;

  final String? ownerName;
  final double? ownerRating;

  /// Display badge: "Yuk egasi" | "Logist" | "LoadMe AI".
  final String? roleBadge;
  final bool verified;

  /// `is_partial` → "Qisman" vs "To'liq".
  final bool isPartial;
  final bool isActive;

  /// Backend wishlist saved-state for the current viewer (`is_favorite` on the
  /// `/loads/` list cards and the detail response; false for guests and for
  /// loads the viewer hasn't saved). The bookmark icon reads this as its source
  /// of truth, so saved-state survives without a separate favorites-list fetch.
  final bool isFavorite;

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
