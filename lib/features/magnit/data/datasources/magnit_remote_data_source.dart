import 'package:dio/dio.dart';
import 'package:loadme_mobile/features/magnit/domain/entities/magnit_activation.dart';
import 'package:loadme_mobile/features/magnit/domain/entities/magnit_truck_type.dart';

/// Talks to the real LoadMe magnet endpoints.
///
/// * `GET  /trucks/types/`          — the truck-type directory (id + name)
/// * `POST /trucks/routes/magnet/`  — activate an auto truck-route alert
///
/// Both responses use the `{ success, data }` envelope. The types payload is a
/// bare list under `data`; the magnet payload is an object that is either
/// `{ route: { id } }` on success or `{ status: 'truck_required' }` when the
/// carrier still has to add a truck of the chosen type.
class MagnitRemoteDataSource {
  MagnitRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<MagnitTruckType>> getTruckTypes() async {
    final res = await _dio.get<dynamic>('/trucks/types/');
    return _flattenTypes(_peel(res.data))
        .map(_parseType)
        .whereType<MagnitTruckType>()
        .toList();
  }

  /// The truck-model catalogue (`GET /trucks/models/`) — same envelope + id/name
  /// shape as the type directory, so it reuses the tolerant list parser. Each
  /// entry's id is the `truck_model` UUID the create form sends.
  Future<List<MagnitTruckType>> getTruckModels() async {
    final res = await _dio.get<dynamic>('/trucks/models/');
    return _listOf(res).map(_parseType).whereType<MagnitTruckType>().toList();
  }

  Future<MagnitActivation> activate({
    required String truckType,
    String? pickupCountry,
    String? pickupRegion,
    String? pickupDistrict,
    String? deliveryCountry,
    String? deliveryRegion,
    String? deliveryDistrict,
    int? deadheadRadiusKm,
  }) async {
    // Only the documented `truck_type` is mandatory; every location id is sent
    // under its own filter key and omitted when null so validation never trips
    // on an empty string.
    final body = <String, dynamic>{
      'truck_type': truckType,
      if (pickupCountry != null) 'pickup_country': pickupCountry,
      if (pickupRegion != null) 'pickup_region': pickupRegion,
      if (pickupDistrict != null) 'pickup_district': pickupDistrict,
      if (deliveryCountry != null) 'delivery_country': deliveryCountry,
      if (deliveryRegion != null) 'delivery_region': deliveryRegion,
      if (deliveryDistrict != null) 'delivery_district': deliveryDistrict,
      if (deadheadRadiusKm != null) 'deadhead_radius_km': deadheadRadiusKm,
    };

    final res =
        await _dio.post<dynamic>('/trucks/routes/magnet/', data: body);
    final data = _peel(res.data);

    final status = data is Map ? _str(data['status']) : null;
    if (status == 'truck_required') {
      return const MagnitActivation(status: MagnitStatus.truckRequired);
    }

    String? routeId;
    if (data is Map) {
      final route = data['route'];
      if (route is Map) routeId = _str(route['id'] ?? route['guid']);
      routeId ??= _str(data['id'] ?? data['guid']);
    }
    return MagnitActivation(status: MagnitStatus.activated, routeId: routeId);
  }

  // ---------------------------------------------------------------------------
  // Parsing
  // ---------------------------------------------------------------------------

  MagnitTruckType? _parseType(Map<String, dynamic> m) {
    final id = _str(m['id'] ?? m['guid']);
    final name = _str(
      m['name'] ??
          m['name_uz'] ??
          m['name_ru'] ??
          m['name_en'] ??
          m['title'] ??
          m['model_name'],
    );
    if (id == null || name == null) return null;
    return MagnitTruckType(id: id, name: name);
  }

  /// Flattens the truck-type directory into a flat, de-duplicated list of
  /// selectable leaf types.
  ///
  /// `GET /trucks/types/` does NOT return a bare list — it groups types:
  /// `data: { top: [...], categories: [ { id, name, children: [type...] } ] }`.
  /// The selectable types are the leaves: a node with a non-empty `children`
  /// list is a *category* (recurse into it, never list it), a node without
  /// children is a real type. `top` is just a popular subset, so it is only
  /// used as a fallback when `categories` is absent. Older/simple shapes
  /// (`data: [...]`, `data.results`, `data.types`) still work.
  List<Map<String, dynamic>> _flattenTypes(dynamic inner) {
    final out = <String, Map<String, dynamic>>{}; // keyed by id → dedupe

    void addLeaf(Map<dynamic, dynamic> node) {
      final children = node['children'];
      if (children is List && children.isNotEmpty) {
        for (final c in children) {
          if (c is Map) addLeaf(c);
        }
        return;
      }
      final id = _str(node['id'] ?? node['guid']);
      if (id != null) out[id] = Map<String, dynamic>.from(node);
    }

    if (inner is List) {
      for (final e in inner) {
        if (e is Map) addLeaf(e);
      }
    } else if (inner is Map) {
      final categories = inner['categories'];
      if (categories is List && categories.isNotEmpty) {
        for (final c in categories) {
          if (c is Map) addLeaf(c);
        }
      } else {
        final list = inner['results'] ?? inner['types'] ?? inner['top'];
        if (list is List) {
          for (final e in list) {
            if (e is Map) addLeaf(e);
          }
        }
      }
    }
    return out.values.toList();
  }

  /// Peels the envelope and returns the contained list (a bare `data` list or a
  /// paginated `data.results`), as a list of maps.
  List<Map<String, dynamic>> _listOf(Response<dynamic> res) {
    final inner = _peel(res.data);
    final list = inner is List
        ? inner
        : (inner is Map ? (inner['results'] ?? inner['types']) : null);
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Peels the `{ success, data }` envelope when present.
  dynamic _peel(dynamic body) {
    if (body is Map && body.containsKey('data') && body['data'] != null) {
      return body['data'];
    }
    return body;
  }

  String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}
