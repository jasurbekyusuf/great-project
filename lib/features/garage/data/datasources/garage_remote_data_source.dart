import 'package:dio/dio.dart';
import 'package:loadme_mobile/features/garage/data/datasources/garage_data_source.dart';
import 'package:loadme_mobile/features/garage/domain/entities/garage_route.dart';
import 'package:loadme_mobile/features/garage/domain/entities/garage_vehicle.dart';
import 'package:loadme_mobile/features/garage/domain/entities/transport_detail.dart';

/// Dio-backed [GarageDataSource] talking to the real LoadMe truck endpoints.
///
/// The garage screen is a view onto the truck domain:
/// * Transportlar (vehicles)  → `GET /trucks/`
/// * Yo'nalishlarim (routes)  → `GET /trucks/routes/` (the caller's own)
/// * Transport detail         → `GET /trucks/routes/available/{id}/`
///   (falls back to `/trucks/routes/{id}/`, then `/trucks/{id}/`)
/// * Pause / resume a route   → `POST /trucks/routes/{id}/archive|unarchive/`
/// * Delete a route           → `DELETE /trucks/routes/{id}/`
///
/// Same `{ success, data }` envelope and `{ results, ... }` pagination as
/// `TrucksRemoteDataSource`; nested `owner` / `truck` / `currency` /
/// `pickup_*` / `delivery_*` objects are flattened into the garage entities
/// here so the presentation layer never touches raw JSON.
class GarageRemoteDataSource implements GarageDataSource {
  GarageRemoteDataSource(this._dio);
  final Dio _dio;

  /// The garage lists are short, so one large page is fetched instead of
  /// paginating (the [GarageDataSource] contract takes no page argument).
  static const _pageSize = 100;

  @override
  Future<List<GarageVehicle>> getVehicles() async {
    final res = await _dio.get<dynamic>('/trucks/', queryParameters: {
      'page': 1,
      'page_size': _pageSize,
    });
    return _resultsOf(res).map(_parseVehicle).toList();
  }

  @override
  Future<void> addVehicle(GarageVehicle vehicle) async {
    // `POST /trucks/` is multipart/form-data. `model_name` + `truck_type` are
    // the essential fields; capacity (measurement_value/unit) and plate_number
    // are sent when present. Image/certificate uploads stay optional for now.
    final form = FormData.fromMap(<String, dynamic>{
      if (vehicle.model.isNotEmpty) 'model_name': vehicle.model,
      if (vehicle.truckModelId != null) 'truck_model': vehicle.truckModelId,
      if (vehicle.truckTypeId != null) 'truck_type': vehicle.truckTypeId,
      if (vehicle.measurementValue != null)
        'measurement_value': vehicle.measurementValue,
      if (vehicle.measurementUnit != null)
        'measurement_unit': vehicle.measurementUnit,
      if (vehicle.plate.isNotEmpty) 'plate_number': vehicle.plate,
    });
    await _dio.post<dynamic>('/trucks/', data: form);
  }

  @override
  Future<List<GarageRoute>> getRoutes() async {
    // `is_active` is omitted so paused routes appear alongside active ones.
    final res = await _dio.get<dynamic>('/trucks/routes/', queryParameters: {
      'page': 1,
      'page_size': _pageSize,
    });
    return _resultsOf(res).map(_parseRoute).toList();
  }

  @override
  Future<void> addRoute(GarageRoute route) async {
    // Best-effort create (the post-truck screen owns real route creation); only
    // the fields the entity carries are sent.
    await _dio.post<dynamic>('/trucks/routes/', data: {
      'note': route.name,
      'is_partial': route.loadKind.toLowerCase().contains('qisman'),
    });
  }

  @override
  Future<TransportDetail> getTransportDetail(String id) async {
    return _parseDetail(await _fetchDetail(id), id);
  }

  @override
  Future<void> toggleRoute(String id) async {
    // The contract gives only the id, so the route's current state is read first
    // and the opposite action is posted.
    final res = await _dio.get<dynamic>('/trucks/routes/$id/');
    if (_activeOf(_objOf(res))) {
      await _dio.post<dynamic>('/trucks/routes/$id/archive/');
    } else {
      await _dio.post<dynamic>('/trucks/routes/$id/unarchive/');
    }
  }

  @override
  Future<void> deleteRoute(String id) async {
    await _dio.delete<dynamic>('/trucks/routes/$id/');
  }

  /// Detail lookup with the same 3-level fallback as the trucks data source:
  /// public route → owner's route → bare vehicle.
  Future<Map<String, dynamic>> _fetchDetail(String id) async {
    try {
      final res = await _dio.get<dynamic>('/trucks/routes/available/$id/');
      return _objOf(res);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        try {
          final res = await _dio.get<dynamic>('/trucks/routes/$id/');
          return _objOf(res);
        } on DioException catch (e2) {
          if (e2.response?.statusCode == 404) {
            final res = await _dio.get<dynamic>('/trucks/$id/');
            return _objOf(res);
          }
          rethrow;
        }
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Parsing
  // ---------------------------------------------------------------------------

  GarageVehicle _parseVehicle(Map<String, dynamic> data) {
    return GarageVehicle(
      id: (data['id'] ?? data['guid'] ?? '').toString(),
      name: _typeName(
              data['truck_type'] ?? data['truck_type_data'] ?? data['type']) ??
          _truckName(data) ??
          '—',
      model: _str(data['model_name'] ?? data['model'] ?? data['name']) ?? '',
      plate: _str(data['plate_number'] ?? data['plate']) ?? '',
      photoUrl: _media(data['image'] ?? data['photo']),
    );
  }

  GarageRoute _parseRoute(Map<String, dynamic> data) {
    final owner = _mapOf(data['owner']);
    final truck = _mapOf(data['truck']);
    final currency = _mapOf(data['currency']);
    final price = _toDouble(data['price']);

    var measurement = _measurement(data);
    if (measurement.$1 == null && measurement.$2 == null && truck.isNotEmpty) {
      measurement = _measurement(truck);
    }

    return GarageRoute(
      id: (data['id'] ?? data['guid'] ?? '').toString(),
      name: _truckName(truck.isNotEmpty ? truck : data) ??
          _ownerName(owner) ??
          '—',
      plate: _str(truck['plate_number'] ??
              truck['plate'] ??
              data['plate_number']) ??
          '',
      priceLabel: _priceLabel(price, currency),
      fromCity: _city(data, 'pickup'),
      fromCountry: _code(data['pickup_country']) ?? '',
      toCity: _city(data, 'delivery'),
      toCountry: _code(data['delivery_country']) ?? '',
      distanceKm: _toInt(data['distance_km']) ?? 0,
      weightT: measurement.$1 ?? 0,
      loadKind: (data['is_partial'] ?? false) == true ? 'Qisman' : "To'liq",
      active: _activeOf(data),
      avatarUrl: _media(owner['photo'] ?? owner['image'] ?? owner['avatar']),
    );
  }

  TransportDetail _parseDetail(Map<String, dynamic> data, String id) {
    final owner = _mapOf(data['owner']);
    final truck = _mapOf(data['truck']);
    // A bare vehicle payload has no nested `truck`, so read from `data`.
    final v = truck.isNotEmpty ? truck : data;
    final currency = _mapOf(data['currency']);
    final price = _toDouble(data['price']);

    var measurement = _measurement(data);
    if (measurement.$1 == null && measurement.$2 == null && truck.isNotEmpty) {
      measurement = _measurement(truck);
    }
    final isPartial = (data['is_partial'] ?? false) == true;

    return TransportDetail(
      id: (data['id'] ?? data['guid'] ?? id).toString(),
      vehicleName: _truckName(v) ?? '—',
      vehicleModel: _str(v['model_name'] ?? v['model'] ?? v['name']) ?? '',
      plate: _str(v['plate_number'] ?? v['plate']) ?? '',
      fromCity: _city(data, 'pickup'),
      fromSubtitle: _subtitle(data, 'pickup'),
      fromDate:
          _uzDate((data['departure_date'] ?? data['pickup_date'])?.toString()),
      toCity: _city(data, 'delivery'),
      toSubtitle: _subtitle(data, 'delivery'),
      toDate:
          _uzDate((data['arrival_date'] ?? data['delivery_date'])?.toString()),
      paymentLabel: _paymentLabel(data['payment_type'] ?? data['payment']),
      priceLabel: _priceLabel(price, currency),
      loadType: isPartial ? 'Qisman' : "To'liq",
      radius: _kmLabel(_toInt(data['deadhead_radius_km'] ??
          data['radius_km'] ??
          data['deadhead_km'])),
      distance: _kmLabel(_toInt(data['distance_km'])),
      weight: measurement.$1 != null ? '${_num(measurement.$1!)} t' : '—',
      capacity: measurement.$2 != null ? '${_num(measurement.$2!)} m³' : '—',
      comment: _str(data['note'] ?? data['comment']) ?? '',
      contactName: _ownerName(owner) ?? '—',
      contactRating: _toDouble(owner['rating'] ?? data['rating']) ?? 0,
      telegram:
          _str(owner['telegram_username'] ?? data['telegram_username']) ?? '',
      whatsapp: _str(owner['whatsapp_number'] ?? data['whatsapp_number']) ?? '',
      phone: _str(owner['phone_number'] ??
          data['phone'] ??
          data['phone_number'] ??
          v['phone_number']),
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
  /// map falls back to the city lookup.
  double? _geoCoord(Map<String, dynamic> data, String prefix, String which) {
    final isLat = which == 'latitude';
    final short = isLat ? 'lat' : 'lng';

    // 1) Flat scalar fields written by this client on create/update.
    var v = _toDouble(data['${prefix}_$which'] ?? data['${prefix}_$short']);

    // 2) Walk the candidate objects (point first, then the location, then the
    //    district/region centroid).
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

  // ---------------------------------------------------------------------------
  // Field helpers
  // ---------------------------------------------------------------------------

  /// City line for a card — district, else region, else the free-text location,
  /// else the country name.
  String _city(Map<String, dynamic> data, String prefix) {
    return _name(data['${prefix}_district']) ??
        _name(data['${prefix}_region']) ??
        _str(data['${prefix}_location']) ??
        _name(data['${prefix}_country']) ??
        '—';
  }

  /// "Region, COUNTRY" subtitle under the city ("Qashqadaryo, UZ").
  String _subtitle(Map<String, dynamic> data, String prefix) {
    final region = _name(data['${prefix}_region']);
    final country = _code(data['${prefix}_country']);
    return [region, country].whereType<String>().join(', ');
  }

  /// ISO date → Uzbek "4-iyun".
  String _uzDate(String? iso) {
    if (iso == null) return '—';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '—';
    const months = [
      'yanvar', 'fevral', 'mart', 'aprel', 'may', 'iyun',
      'iyul', 'avgust', 'sentabr', 'oktabr', 'noyabr', 'dekabr', //
    ];
    return '${dt.day}-${months[dt.month - 1]}';
  }

  /// `payment_type` → Uzbek label.
  String _paymentLabel(dynamic raw) {
    final s = _str(raw);
    if (s == null) return '—';
    final l = s.toLowerCase();
    if (l.contains('cash') || l.contains('naqd')) return 'Naqd';
    if (l.contains('card') || l.contains('karta')) return 'Karta';
    if (l.contains('transfer') || l.contains('bank') || l.contains('otkazma')) {
      return "O'tkazma";
    }
    return s;
  }

  String _kmLabel(int? km) => km == null ? '—' : '$km km';

  /// Formats a measurement without a trailing ".0" ("4.0" → "4").
  String _num(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

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

  /// Vehicle card-title — its model, else the truck-type display name. A bare
  /// UUID truck-type stays unresolved (null).
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

  String _priceLabel(double? price, Map<String, dynamic> currency) {
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
