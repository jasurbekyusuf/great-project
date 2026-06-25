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
    );
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
