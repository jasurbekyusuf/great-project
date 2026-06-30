import 'package:dio/dio.dart';
import 'package:loadme_mobile/features/locations/domain/entities/location_entity.dart';

/// Talks to `GET /api/v1/locations/search/` — the same endpoint the web app's
/// load filter uses for "Qayerdan / Qayerga" autocomplete. Returns a flat,
/// already-ranked mix of countries, regions and districts matching `q`.
///
/// The response envelope is
/// `{ success, data: [ { type, id, name, region_name, country_name, ... } ] }`.
/// The call is sent **anonymously** (`__anon`) because the directory is public
/// — guests rely on it too, and a stale token must never turn an autocomplete
/// lookup into a 401.
class LocationsRemoteDataSource {
  LocationsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<LocationEntity>> search(String query, {int limit = 20}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final res = await _dio.get<dynamic>(
      '/locations/search/',
      queryParameters: {'q': q, 'limit': limit},
      options: Options(extra: const {'__anon': true}),
    );
    return _listOf(res).map(_parse).whereType<LocationEntity>().toList();
  }

  /// Reverse-geocodes a device GPS fix to the nearest directory place via
  /// `GET /locations/reverse/?lat=&lng=` — the source for "Mening joylashuvim"
  /// in the pickup sheet. Sent anonymously (public directory). Returns null when
  /// the backend can't match the coordinates to a known region/district.
  ///
  /// The payload is a **nested** object keyed by level —
  /// `data: { country:{id,name}, region:{id,name}, district:{id,name} }` — not
  /// the flat `{type,id,name}` the search endpoint uses. We collapse it to the
  /// most specific level present (district → region → country) while keeping the
  /// parent ids so the result carries the full chain.
  Future<LocationEntity?> reverse({
    required double lat,
    required double lng,
  }) async {
    final res = await _dio.get<dynamic>(
      '/locations/reverse/',
      queryParameters: {'lat': lat, 'lng': lng},
      options: Options(extra: const {'__anon': true}),
    );
    final body = res.data;
    final inner = (body is Map && body['data'] != null) ? body['data'] : body;
    if (inner is! Map) return null;

    Map<String, dynamic>? level(String key) {
      final v = inner[key];
      return v is Map ? Map<String, dynamic>.from(v) : null;
    }

    final country = level('country');
    final region = level('region');
    final district = level('district');

    final countryId = country == null ? null : _str(country['id']);
    final regionId = region == null ? null : _str(region['id']);

    if (district != null && _str(district['id']) != null) {
      return LocationEntity(
        id: _str(district['id'])!,
        name: _str(district['name']) ?? '',
        kind: LocationFilterKind.district,
        regionName: region == null ? null : _str(region['name']),
        countryName: country == null ? null : _str(country['name']),
        countryId: countryId,
        regionId: regionId,
        latitude: lat,
        longitude: lng,
      );
    }
    if (region != null && _str(region['id']) != null) {
      return LocationEntity(
        id: _str(region['id'])!,
        name: _str(region['name']) ?? '',
        kind: LocationFilterKind.region,
        countryName: country == null ? null : _str(country['name']),
        countryId: countryId,
        latitude: lat,
        longitude: lng,
      );
    }
    if (country != null && _str(country['id']) != null) {
      return LocationEntity(
        id: _str(country['id'])!,
        name: _str(country['name']) ?? '',
        kind: LocationFilterKind.country,
        latitude: lat,
        longitude: lng,
      );
    }
    return null;
  }

  LocationEntity? _parse(Map<String, dynamic> m) {
    final id = _str(m['id']);
    final name = _str(m['name']);
    if (id == null || name == null) return null;
    final kind = _kind(_str(m['type']));
    return LocationEntity(
      id: id,
      name: name,
      kind: kind,
      regionName: _str(m['region_name']),
      // A country row's country_name just repeats the name — drop it.
      countryName:
          kind == LocationFilterKind.country ? null : _str(m['country_name']),
      // Parent ids + centroid (search payload also returns these); carried so
      // callers needing the full country→region→district chain (magnet/route
      // creation) or a proximity anchor don't have to re-resolve them.
      countryId: _str(m['country_id']),
      regionId: _str(m['region_id']),
      latitude: _toDouble(m['latitude']),
      longitude: _toDouble(m['longitude']),
    );
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  LocationFilterKind _kind(String? type) {
    switch (type) {
      case 'country':
        return LocationFilterKind.country;
      case 'district':
        return LocationFilterKind.district;
      case 'region':
      default:
        return LocationFilterKind.region;
    }
  }

  /// Peels the `{ success, data }` envelope and returns `data` as a list of
  /// maps (the search payload is a bare array, not a paginated `results`).
  List<Map<String, dynamic>> _listOf(Response<dynamic> res) {
    final body = res.data;
    final inner = (body is Map && body['data'] != null) ? body['data'] : body;
    if (inner is! List) return const [];
    return inner
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}
