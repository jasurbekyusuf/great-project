/// A place returned by `GET /api/v1/locations/search/` — a country, region or
/// district the user can filter loads/trucks by.
///
/// The backend's load feed is filtered by **id**, keyed on the `kind`: a region
/// pick becomes `pickup_region=<id>` / `delivery_region=<id>`, a district
/// `pickup_district=<id>`, a country `pickup_country=<id>`. `filterKey` yields
/// the `region` / `district` / `country` suffix for that param.
enum LocationFilterKind { country, region, district }

class LocationEntity {
  const LocationEntity({
    required this.id,
    required this.name,
    required this.kind,
    this.regionName,
    this.countryName,
    this.countryId,
    this.regionId,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final LocationFilterKind kind;

  /// Parent region label — set for districts, null for regions / countries.
  final String? regionName;

  /// Country label (e.g. "Oʻzbekiston"). Null for a country row, where it
  /// would just repeat [name].
  final String? countryName;

  /// Parent **country id** (search payload `country_id`) — present for region
  /// and district rows, null for a country row (its own [id] is the country).
  /// Needed when a sibling endpoint requires the full country→region→district
  /// chain (e.g. magnet/route creation, where `pickup_country` is mandatory).
  final String? countryId;

  /// Parent **region id** (search payload `region_id`) — present for district
  /// rows only; null for regions / countries.
  final String? regionId;

  /// Place centroid (search payload `latitude` / `longitude`), usable as a
  /// proximity anchor without a device GPS fix. Null when the row omits it.
  final double? latitude;
  final double? longitude;

  /// The `/loads/available/` query-param suffix: `country` | `region` |
  /// `district`. Combine as `pickup_$filterKey` / `delivery_$filterKey`.
  String get filterKey => kind.name;

  /// "<region>, <country>" minus the empty parts — the muted second line under
  /// the name in the suggestions list. Null when there is nothing to add.
  String? get subtitle {
    final parts = [
      if (regionName != null && regionName!.isNotEmpty) regionName!,
      if (countryName != null && countryName!.isNotEmpty) countryName!,
    ];
    return parts.isEmpty ? null : parts.join(', ');
  }
}
