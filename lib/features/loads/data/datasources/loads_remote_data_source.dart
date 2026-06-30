import 'package:dio/dio.dart';
import 'package:loadme_mobile/features/loads/domain/entities/load_draft.dart';
import 'package:loadme_mobile/features/loads/domain/entities/load_entity.dart';

/// Talks to the real LoadMe `/loads/` endpoints.
///
/// * `GET /loads/available/`        — public marketplace feed (guest + auth)
/// * `GET /loads/`                  — the caller's own loads (`is_active` filter)
/// * `GET /loads/available/{id}/`   — detail (falls back to `/loads/{id}/`)
/// * `POST /loads/`                 — create (multipart)
/// * `PATCH /loads/{id}/`           — update (multipart)
/// * `DELETE /loads/{id}/`          — archive (closing a load)
/// * `POST /loads/{id}/restore/`    — re-activate an archived load
///
/// The response envelope is `{ success, data }`; paginated payloads carry
/// `{ results, count, next, previous }`. Nested `owner`, `currency` and
/// `pickup_*` / `delivery_*` location objects are flattened directly into the
/// enriched [LoadEntity] here so the rest of the app never touches raw JSON.
class LoadsRemoteDataSource {
  LoadsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<LoadEntity>> getLoads({
    required int page,
    required int limit,
    Map<String, String>? filters,
  }) async {
    final res = await _dio.get<dynamic>('/loads/available/', queryParameters: {
      'page': page,
      'page_size': limit,
      // Location filters keyed by the picked place's kind, e.g.
      // `pickup_region` / `delivery_district` → a UUID (see LocationEntity).
      ...?filters,
    });
    return _resultsOf(res).map(_parseLoad).toList();
  }

  /// Total number of public loads (the paginated `count`). Asks for a single
  /// row to keep the payload tiny — we only need the header total. When
  /// [filters] are supplied (a `pickup_*` / `delivery_*` search), the count is
  /// the filtered total — i.e. the "Topildi: N" header after a Qidiruv.
  Future<int> getLoadsCount({Map<String, String>? filters}) async {
    final res = await _dio.get<dynamic>('/loads/available/', queryParameters: {
      'page': 1,
      'page_size': 1,
      ...?filters,
    });
    return _countOf(res);
  }

  Future<List<LoadEntity>> getUserLoads({
    required int page,
    required int limit,
    required bool isActive,
    String? userGuid,
  }) async {
    final res = await _dio.get<dynamic>('/loads/', queryParameters: {
      'page': page,
      'page_size': limit,
      'is_active': isActive,
    });
    return _resultsOf(res).map(_parseLoad).toList();
  }

  Future<LoadEntity> getLoadById(String id) async {
    try {
      final res = await _dio.get<dynamic>('/loads/available/$id/');
      return _parseLoad(_objOf(res));
    } on DioException catch (e) {
      // The public detail route 404s for the owner's own (non-public) loads —
      // retry the authenticated endpoint before giving up.
      if (e.response?.statusCode == 404) {
        final res = await _dio.get<dynamic>('/loads/$id/');
        return _parseLoad(_objOf(res));
      }
      rethrow;
    }
  }

  Future<void> addLoad(LoadDraft draft) async {
    await _dio.post<dynamic>('/loads/', data: _draftForm(draft));
  }

  Future<void> updateLoad(String loadId, LoadDraft draft) async {
    await _dio.patch<dynamic>('/loads/$loadId/', data: _draftForm(draft));
  }

  /// Builds the multipart body for create/update, dropping every empty field so
  /// DRF validation never trips on a blank string. The structured location ids
  /// are keyed by the picked place's kind (`pickup_region` / `delivery_district`
  /// …) — the exact contract the browse filter uses — while `from_location` /
  /// `to_location` keep a human-readable fallback for the route label.
  FormData _draftForm(LoadDraft d) {
    final map = <String, dynamic>{
      'from_location': d.fromAddress,
      'to_location': d.toAddress,
    };

    void put(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) map[key] = value.trim();
    }

    if (d.pickupKind != null) put('pickup_${d.pickupKind}', d.pickupId);
    if (d.deliveryKind != null) put('delivery_${d.deliveryKind}', d.deliveryId);
    if (d.truckTypeIds.isNotEmpty) map['truck_type'] = d.truckTypeIds.join(',');
    put('price', d.price);
    put('currency', d.currencyCode);
    put('payment_type', d.paymentType);
    put('measurement_value', d.measurementValue);
    put('measurement_unit', d.measurementUnit);
    put('advance_payment', d.advancePayment);
    put('pickup_date', d.pickupDate);
    put('delivery_date', d.deliveryDate);
    if (d.isPartial != null) map['is_partial'] = d.isPartial.toString();
    put('commodity', d.commodity);
    put('comment', d.comment);

    return FormData.fromMap(map);
  }

  /// Closing a load is a soft DELETE; re-activating restores it. There is no
  /// "closed platform" endpoint on the real backend, so that hint is ignored.
  Future<void> updateLoadStatus({
    required String guid,
    required bool isActive,
    String? closedPlatform,
  }) async {
    if (isActive) {
      await _dio.post<dynamic>('/loads/$guid/restore/');
    } else {
      await _dio.delete<dynamic>('/loads/$guid/');
    }
  }

  // ---------------------------------------------------------------------------
  // Parsing
  // ---------------------------------------------------------------------------

  /// Public passthrough so sibling features (e.g. Saqlanganlar / favorites)
  /// can reuse the exact same enriched load mapping instead of duplicating the
  /// ~150-line `owner` / `currency` / location flattening.
  LoadEntity parseLoad(Map<String, dynamic> json) => _parseLoad(json);

  LoadEntity _parseLoad(Map<String, dynamic> data) {
    final owner = data['owner'] is Map
        ? Map<String, dynamic>.from(data['owner'] as Map)
        : const <String, dynamic>{};
    final currency = data['currency'] is Map
        ? Map<String, dynamic>.from(data['currency'] as Map)
        : const <String, dynamic>{};

    final price = _toDouble(data['price']);
    final isBot = (owner['is_bot'] ?? data['is_bot'] ?? false) == true;
    final createdAt = data['created_at']?.toString();

    final measurement = _measurement(data);

    return LoadEntity(
      guid: (data['id'] ?? data['guid'] ?? '').toString(),
      fromAddress: _composeAddress(data, 'pickup'),
      toAddress: _composeAddress(data, 'delivery'),
      fromCountry: _code(data['pickup_country']),
      toCountry: _code(data['delivery_country']),
      comment: _str(data['comment']),
      commodity: _str(data['commodity']),
      price: price,
      priceLabel: _priceLabel(price, currency),
      advanceLabel: _advanceLabel(_toDouble(data['advance_payment']), currency),
      pickupDate: data['pickup_date']?.toString(),
      deliveryDate: data['delivery_date']?.toString(),
      createdAt: createdAt,
      timeAgo: _timeAgo(createdAt),
      truckType: _truckType(data['truck_type']),
      weightT: measurement.$1,
      volumeM3: measurement.$2,
      distanceKm: _toInt(data['distance_km']),
      radiusKm: _toInt(data['radius_km'] ??
          data['deadhead_radius_km'] ??
          data['pickup_radius_km']),
      ownerId: _str(
          owner['id'] ?? owner['guid'] ?? owner['user_id'] ?? owner['user']),
      ownerName: _str(owner['display_name'] ??
          owner['full_name'] ??
          owner['company_name'] ??
          owner['name']),
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
      isFavorite: (data['is_favorite'] ?? data['is_saved'] ?? false) == true,
      phone:
          _str(owner['phone_number'] ?? data['phone'] ?? data['phone_number']),
      telegram: _str(owner['telegram_username'] ?? data['telegram_username']),
      whatsapp: _str(owner['whatsapp_number'] ?? data['whatsapp_number']),
      pickupLat: _geoCoord(data, 'pickup', 'latitude'),
      pickupLng: _geoCoord(data, 'pickup', 'longitude'),
      deliveryLat: _geoCoord(data, 'delivery', 'latitude'),
      deliveryLng: _geoCoord(data, 'delivery', 'longitude'),
    );
  }

  /// Reads a pickup/delivery coordinate, tolerating every shape the backend
  /// uses for a PostGIS point:
  ///   • flat scalars        `pickup_latitude` / `pickup_lat`
  ///   • nested location     `pickup` | `pickup_location` `{ latitude }`
  ///   • GeoJSON Point       `pickup_point: { coordinates: [lng, lat] }`
  ///   • district/region     `pickup_district: { point|centroid: … }` centroid
  /// A `0` is treated as "unset" (the backend's null-island placeholder) so the
  /// map falls back to the city lookup instead of pointing at the Gulf of
  /// Guinea.
  double? _geoCoord(Map<String, dynamic> data, String prefix, String which) {
    final isLat = which == 'latitude';
    final short = isLat ? 'lat' : 'lng';

    // 1) Flat scalar fields written by this client on create/update.
    var v = _toDouble(data['${prefix}_$which'] ?? data['${prefix}_$short']);

    // 2) Walk the candidate objects (point first, then the location, then the
    //    district/region centroid) and read latitude/lat, a GeoJSON
    //    `coordinates: [lng, lat]` array, or a nested point/centroid.
    if (v == null) {
      for (final key in [
        '${prefix}_point',
        prefix,
        '${prefix}_location',
        '${prefix}_district',
        '${prefix}_region',
      ]) {
        final obj = data[key];
        if (obj is! Map) continue;
        v = _coordFromObject(Map<String, dynamic>.from(obj), isLat, which, short);
        if (v != null) break;
      }
    }

    if (v == null || v == 0) return null;
    return v;
  }

  /// Pulls a single lat/lng out of a location-ish object: a direct
  /// `latitude`/`lat` key, a GeoJSON `coordinates: [lng, lat]` array, or a
  /// nested `point` / `centroid` sub-object (district/region centroids).
  double? _coordFromObject(
    Map<String, dynamic> obj,
    bool isLat,
    String which,
    String short,
  ) {
    final direct = _toDouble(obj[which] ?? obj[short]);
    if (direct != null) return direct;

    final coords = obj['coordinates'];
    if (coords is List && coords.length >= 2) {
      // GeoJSON is [longitude, latitude].
      return _toDouble(isLat ? coords[1] : coords[0]);
    }

    for (final nested in [obj['point'], obj['centroid'], obj['location']]) {
      if (nested is Map) {
        final v = _coordFromObject(
            Map<String, dynamic>.from(nested), isLat, which, short);
        if (v != null) return v;
      }
    }
    return null;
  }

  /// Builds a "district, region" line, falling back to the free-text
  /// `*_location` string and finally the country name.
  ///
  /// The free-text fallback is side-aware: pickup falls back to `from_location`,
  /// delivery to `to_location` — the exact fields this client writes when
  /// creating/updating a load (see [addLoad]/[updateLoad]). Using `from_location`
  /// for both sides made a load without `delivery_location` show its *pickup*
  /// text as the destination.
  String _composeAddress(Map<String, dynamic> data, String prefix) {
    final district = _name(data['${prefix}_district']);
    final region = _name(data['${prefix}_region']);
    final parts = [district, region].whereType<String>().toList();
    if (parts.isNotEmpty) return parts.join(', ');
    final freeText =
        prefix == 'delivery' ? data['to_location'] : data['from_location'];
    final loc = _str(data['${prefix}_location'] ?? freeText);
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

  String? _priceLabel(double? price, Map<String, dynamic> currency) {
    if (price == null || price <= 0) return 'Kelishiladi';
    final code = currency['code']?.toString();
    final symbol = currency['symbol']?.toString();
    final unit = (code == null || code == 'UZS') ? "so'm" : (symbol ?? code);
    return '${_group(price)} $unit';
  }

  /// Advance/prepayment label ("30 000 000 so'm"). Unlike [_priceLabel] there is
  /// no "Kelishiladi" fallback — a missing advance returns null so the route
  /// card shows a dash instead.
  String? _advanceLabel(double? advance, Map<String, dynamic> currency) {
    if (advance == null || advance <= 0) return null;
    final code = currency['code']?.toString();
    final symbol = currency['symbol']?.toString();
    final unit = (code == null || code == 'UZS') ? "so'm" : (symbol ?? code);
    return '${_group(advance)} $unit';
  }

  /// Groups the integer part with non-breaking-ish space separators
  /// ("20000000" → "20 000 000").
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

  String? _truckType(dynamic raw) {
    if (raw is Map) return _str(raw['name'] ?? raw['title']);
    return null; // bare UUID — unresolved without the types directory
  }

  bool _activeOf(Map<String, dynamic> data) {
    final a = data['is_active'];
    if (a is bool) return a;
    final s = data['status']?.toString().toLowerCase();
    if (s != null && s.isNotEmpty) return s == 'active';
    return true;
  }

  // ---------------------------------------------------------------------------
  // Envelope + primitive helpers
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> _resultsOf(Response<dynamic> res) {
    final inner = _peel(res.data);
    final list = inner is List
        ? inner
        : (inner is Map
            ? (inner['results'] ?? inner['result'] ?? inner['loads'])
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
      final c =
          _toInt(inner['count'] ?? inner['total'] ?? inner['total_count']);
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
