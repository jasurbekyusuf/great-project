import 'package:dio/dio.dart';
import 'package:loadme_mobile/features/trucks/domain/entities/truck_detail_entity.dart';
import 'package:loadme_mobile/features/trucks/domain/entities/truck_entity.dart';

/// Talks to the real LoadMe truck endpoints.
///
/// A "posted truck" is a published route (`/trucks/routes/`); a "truck" is the
/// physical vehicle in the carrier's garage (`/trucks/`).
///
/// * `GET  /trucks/routes/available/`      — public posted-route feed
/// * `GET  /trucks/routes/`                — the caller's own routes (`is_active`)
/// * `GET  /trucks/`                        — the caller's vehicles
/// * `GET  /trucks/routes/available/{id}/`  — detail (falls back to `/trucks/{id}/`)
/// * `POST /trucks/routes/{id}/archive/`    — take a route offline
/// * `POST /trucks/routes/{id}/unarchive/`  — re-publish a route
/// * `POST /trucks/{id}/restore/`           — restore an archived vehicle
/// * `DELETE /trucks/{id}/`                 — archive a vehicle
///
/// The response envelope is `{ success, data }`; paginated payloads carry
/// `{ results, count, next, previous }`. Nested `owner`, `truck` (vehicle),
/// `currency` and `pickup_*` / `delivery_*` location objects are flattened
/// directly into the enriched [TruckEntity] here so the rest of the app never
/// touches raw JSON. Mirrors `LoadsRemoteDataSource`.
class TrucksRemoteDataSource {
  TrucksRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<TruckEntity>> getTrucks({
    required int page,
    required int limit,
    Map<String, String>? filters,
  }) async {
    final res =
        await _dio.get<dynamic>('/trucks/routes/available/', queryParameters: {
      'page': page,
      'page_size': limit,
      // Location filters keyed by the picked place's kind, e.g.
      // `pickup_region` / `delivery_district` → a UUID (mirrors loads).
      ...?filters,
    });
    return _resultsOf(res).map(_parseRoute).toList();
  }

  /// Total number of public truck routes (the paginated `count`). Requests a
  /// single row — we only need the header total, not the page itself. When
  /// [filters] are supplied the count reflects the filtered total.
  Future<int> getTrucksCount({Map<String, String>? filters}) async {
    final res =
        await _dio.get<dynamic>('/trucks/routes/available/', queryParameters: {
      'page': 1,
      'page_size': 1,
      ...?filters,
    });
    return _countOf(res);
  }

  Future<List<TruckEntity>> getMyPostTrucks({
    required int page,
    required int limit,
    required bool isActive,
  }) async {
    final res = await _dio.get<dynamic>('/trucks/routes/', queryParameters: {
      'page': page,
      'page_size': limit,
      'is_active': isActive,
    });
    return _resultsOf(res).map(_parseRoute).toList();
  }

  /// The carrier's own vehicles. These have no route, so the from/to address
  /// lines stay empty and only the vehicle identity (model, capacity) is filled.
  Future<List<TruckEntity>> getMyTrucks({
    required int page,
    required int limit,
  }) async {
    final res = await _dio.get<dynamic>('/trucks/', queryParameters: {
      'page': page,
      'page_size': limit,
    });
    return _resultsOf(res).map(_parseVehicle).toList();
  }

  Future<TruckDetailEntity> getTruckById(String id) async {
    try {
      final res = await _dio.get<dynamic>('/trucks/routes/available/$id/');
      return _parseDetail(_objOf(res), id);
    } on DioException catch (e) {
      // The public route detail 404s for the owner's own (archived) routes and
      // for a bare vehicle id — retry the authenticated endpoints in turn.
      if (e.response?.statusCode == 404) {
        try {
          final res = await _dio.get<dynamic>('/trucks/routes/$id/');
          return _parseDetail(_objOf(res), id);
        } on DioException catch (e2) {
          if (e2.response?.statusCode == 404) {
            final res = await _dio.get<dynamic>('/trucks/$id/');
            return _parseDetail(_objOf(res), id);
          }
          rethrow;
        }
      }
      rethrow;
    }
  }

  /// A posted route is taken offline with `archive`, re-published with
  /// `unarchive`.
  Future<void> updatePostTruckStatus({
    required String guid,
    required bool isActive,
  }) async {
    if (isActive) {
      await _dio.post<dynamic>('/trucks/routes/$guid/unarchive/');
    } else {
      await _dio.post<dynamic>('/trucks/routes/$guid/archive/');
    }
  }

  /// A vehicle is archived with a soft DELETE and brought back with `restore`.
  Future<void> updateTruckStatus({
    required String guid,
    required bool isActive,
  }) async {
    if (isActive) {
      await _dio.post<dynamic>('/trucks/$guid/restore/');
    } else {
      await _dio.delete<dynamic>('/trucks/$guid/');
    }
  }

  // ---------------------------------------------------------------------------
  // Parsing
  // ---------------------------------------------------------------------------

  /// A posted route — owner + nested vehicle (`truck`) + pickup/delivery.
  TruckEntity _parseRoute(Map<String, dynamic> data) {
    final owner = _mapOf(data['owner']);
    final truck = _mapOf(data['truck']);
    final currency = _mapOf(data['currency']);

    final price = _toDouble(data['price']);
    final isBot = (owner['is_bot'] ?? data['is_bot'] ?? false) == true;
    final createdAt = (data['created_at'] ?? data['created_time'])?.toString();

    // Capacity offered on the route, falling back to the vehicle's own rating.
    var measurement = _measurement(data);
    if (measurement.$1 == null && measurement.$2 == null && truck.isNotEmpty) {
      measurement = _measurement(truck);
    }

    return TruckEntity(
      guid: (data['id'] ?? data['guid'] ?? '').toString(),
      fromAddress: _composeAddress(data, 'pickup'),
      toAddress: _composeAddress(data, 'delivery'),
      fromCountry: _code(data['pickup_country']),
      toCountry: _code(data['delivery_country']),
      note: _str(data['note'] ?? data['comment']),
      price: price,
      priceLabel: _priceLabel(price, currency),
      departureDate: (data['departure_date'] ?? data['pickup_date'])?.toString(),
      arrivalDate: (data['arrival_date'] ?? data['delivery_date'])?.toString(),
      createdAt: createdAt,
      timeAgo: _timeAgo(createdAt),
      truckType: _truckName(truck.isNotEmpty ? truck : data),
      weightT: measurement.$1,
      volumeM3: measurement.$2,
      distanceKm: _toInt(data['distance_km']),
      radiusKm: _toInt(data['deadhead_radius_km'] ??
          data['radius_km'] ??
          data['deadhead_km']),
      ownerName: _ownerName(owner),
      ownerRating: _toDouble(owner['rating'] ?? data['rating']),
      roleBadge: _roleBadge(
        isBot: isBot,
        role: (owner['role'] ?? data['role'])?.toString(),
        personType: (owner['person_type'] ?? data['person_type'])?.toString(),
      ),
      verified: (owner['is_verified'] ??
              owner['verified'] ??
              data['is_verified'] ??
              false) ==
          true,
      isPartial: (data['is_partial'] ?? false) == true,
      isActive: _activeOf(data),
      phone: _str(owner['phone_number'] ?? data['phone'] ?? data['phone_number']),
      telegram: _str(owner['telegram_username'] ?? data['telegram_username']),
      whatsapp: _str(owner['whatsapp_number'] ?? data['whatsapp_number']),
    );
  }

  /// A bare garage vehicle (no route) — only the identity + capacity fields.
  TruckEntity _parseVehicle(Map<String, dynamic> data) {
    final owner = _mapOf(data['owner']);
    final currency = _mapOf(data['currency']);
    final price = _toDouble(data['price']);
    final measurement = _measurement(data);
    final createdAt = (data['created_at'] ?? data['created_time'])?.toString();

    return TruckEntity(
      guid: (data['id'] ?? data['guid'] ?? '').toString(),
      fromAddress: _str(data['from_location']) ?? '-',
      toAddress: _str(data['to_location']) ?? '-',
      note: _str(data['note'] ?? data['comment']),
      price: price,
      priceLabel: price == null ? null : _priceLabel(price, currency),
      createdAt: createdAt,
      timeAgo: _timeAgo(createdAt),
      truckType: _truckName(data),
      weightT: measurement.$1,
      volumeM3: measurement.$2,
      ownerName: _ownerName(owner),
      ownerRating: _toDouble(owner['rating']),
      verified: (owner['is_verified'] ?? owner['verified'] ?? false) == true,
      isActive: _activeOf(data),
      phone: _str(owner['phone_number'] ?? data['phone_number']),
    );
  }

  /// Builds the vehicle-centric [TruckDetailEntity] from a route detail (using
  /// the nested `truck`) or a bare vehicle payload.
  TruckDetailEntity _parseDetail(Map<String, dynamic> data, String id) {
    final truck = _mapOf(data['truck']);
    // For a bare vehicle payload there is no nested `truck`, so read `data`.
    final v = truck.isNotEmpty ? truck : data;
    final owner = _mapOf(data['owner'] ?? v['owner']);

    return TruckDetailEntity(
      guid: (data['id'] ?? data['guid'] ?? id).toString(),
      modelName: _truckName(v) ?? '-',
      isActive: _activeOf(data),
      truckType: _typeName(v['truck_type'] ?? v['truck_type_data'] ?? v['type']),
      loadCapacity: _str(data['measurement_unit'] ?? v['measurement_unit']),
      loadCapacityValue:
          _str(data['measurement_value'] ?? v['measurement_value']),
      weight: _str(v['weight_unit']),
      weightValue: _str(v['weight'] ?? v['weight_value']),
      plateNumber: _str(v['plate_number'] ?? v['plate']),
      trailerNumber: _str(v['trailer_number']),
      phone: _str(owner['phone_number'] ?? owner['phone']),
      createdTime: (data['created_at'] ?? data['created_time'])?.toString(),
      isPartial: data['is_partial'] is bool ? data['is_partial'] as bool : null,
      minTemp: _str(data['min_temperature'] ?? v['min_temperature']),
      maxTemp: _str(data['max_temperature'] ?? v['max_temperature']),
      photo: _media(v['image'] ?? v['photo'] ?? data['image']),
      certificates: _mediaList(v['certificates'] ?? data['certificates']),
    );
  }

  /// Builds a "district, region" line, falling back to the free-text
  /// `*_location` string and finally the country name.
  String _composeAddress(Map<String, dynamic> data, String prefix) {
    final district = _name(data['${prefix}_district']);
    final region = _name(data['${prefix}_region']);
    final parts = [district, region].whereType<String>().toList();
    if (parts.isNotEmpty) return parts.join(', ');
    final loc = _str(data['${prefix}_location']);
    if (loc != null) return loc;
    return _name(data['${prefix}_country']) ?? '-';
  }

  /// Returns `(weightT, volumeM3)` from `measurement_value` + `measurement_unit`
  /// — "m3"/"m³" maps to volume, everything else (ton) to weight.
  (double?, double?) _measurement(Map<String, dynamic> data) {
    final value = _toDouble(data['measurement_value'] ?? data['measurement']);
    if (value == null) return (null, null);
    final unit =
        (data['measurement_unit'] ?? data['unit'])?.toString().toLowerCase() ??
            '';
    final isVolume = unit.contains('m3') || unit.contains('m³');
    return isVolume ? (null, value) : (value, null);
  }

  /// Card-title name for the vehicle: its model, else the truck-type display
  /// name. A bare UUID truck-type is left unresolved (null).
  String? _truckName(Map<String, dynamic> src) {
    return _str(src['model_name'] ?? src['model'] ?? src['name']) ??
        _typeName(src['truck_type'] ?? src['truck_type_data'] ?? src['type']);
  }

  String? _typeName(dynamic raw) {
    if (raw is Map) {
      return _str(raw['name'] ??
          raw['name_uz'] ??
          raw['name_ru'] ??
          raw['name_en'] ??
          raw['title']);
    }
    return null; // bare UUID — unresolved without the types directory
  }

  String? _ownerName(Map<String, dynamic> owner) => _str(owner['display_name'] ??
      owner['full_name'] ??
      owner['company_name'] ??
      owner['name']);

  String? _priceLabel(double? price, Map<String, dynamic> currency) {
    if (price == null || price <= 0) return 'Kelishiladi';
    final code = currency['code']?.toString();
    final symbol = currency['symbol']?.toString();
    final unit = (code == null || code == 'UZS') ? "so'm" : (symbol ?? code);
    return '${_group(price)} $unit';
  }

  /// Groups the integer part with space separators ("20000000" → "20 000 000").
  String _group(double value) {
    final digits = value.round().abs().toString();
    final buf = StringBuffer(value < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  String? _timeAgo(String? iso) {
    if (iso == null) return null;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return null;
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'hozir';
    if (diff.inMinutes < 60) return '${diff.inMinutes} daqiqa oldin';
    if (diff.inHours < 24) return '${diff.inHours} soat oldin';
    return '${diff.inDays} kun oldin';
  }

  String? _roleBadge({
    required bool isBot,
    String? role,
    String? personType,
  }) {
    if (isBot) return 'LoadMe AI';
    final r = (role ?? personType ?? '').toLowerCase();
    if (r.isEmpty) return null;
    if (r.contains('broker') || r.contains('logist')) return 'Logist';
    return 'Yuk egasi';
  }

  bool _activeOf(Map<String, dynamic> data) {
    final a = data['is_active'];
    if (a is bool) return a;
    final s = data['status']?.toString().toLowerCase();
    if (s != null && s.isNotEmpty) return s == 'active';
    return true;
  }

  /// Prefixes a relative `/media/...` path with the API origin (baseUrl minus
  /// the `/api/v1` suffix). Absolute URLs pass through untouched.
  String? _media(dynamic v) {
    final s = _str(v);
    if (s == null) return null;
    if (s.startsWith('http')) return s;
    final base = _dio.options.baseUrl;
    final origin =
        base.endsWith('/api/v1') ? base.substring(0, base.length - 7) : base;
    return s.startsWith('/') ? '$origin$s' : '$origin/$s';
  }

  List<String> _mediaList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e is Map ? _media(e['file'] ?? e['url'] ?? e['image']) : _media(e))
        .whereType<String>()
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Envelope + primitive helpers
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> _resultsOf(Response<dynamic> res) {
    final inner = _peel(res.data);
    final list = inner is List
        ? inner
        : (inner is Map
            ? (inner['results'] ?? inner['result'] ?? inner['trucks'])
            : null);
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Map<String, dynamic> _objOf(Response<dynamic> res) {
    final inner = _peel(res.data);
    if (inner is Map) return Map<String, dynamic>.from(inner);
    return <String, dynamic>{};
  }

  /// Reads the paginated `count` from the envelope, falling back to the length
  /// of the returned page when the backend omits a total.
  int _countOf(Response<dynamic> res) {
    final inner = _peel(res.data);
    if (inner is Map) {
      final c = _toInt(inner['count'] ?? inner['total'] ?? inner['total_count']);
      if (c != null) return c;
    }
    return _resultsOf(res).length;
  }

  /// Peels the `{ success, data }` envelope when present.
  dynamic _peel(dynamic body) {
    if (body is Map && body.containsKey('data') && body['data'] != null) {
      return body['data'];
    }
    return body;
  }

  Map<String, dynamic> _mapOf(dynamic o) =>
      o is Map ? Map<String, dynamic>.from(o) : const <String, dynamic>{};

  String? _name(dynamic o) {
    if (o is Map) return _str(o['name']);
    return _str(o);
  }

  String? _code(dynamic country) {
    if (country is Map) return _str(country['code'] ?? country['name']);
    return _str(country);
  }

  String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return double.tryParse(v.toString())?.round();
  }
}
