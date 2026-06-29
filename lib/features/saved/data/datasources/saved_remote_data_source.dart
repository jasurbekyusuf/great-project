import 'package:dio/dio.dart';
import 'package:loadme_mobile/features/loads/data/datasources/loads_remote_data_source.dart';
import 'package:loadme_mobile/features/saved/domain/entities/saved_load.dart';

/// Dio-backed client for the favorites ("Saqlanganlar") endpoints.
///
/// Same `{ success, data }` envelope / `{ results, ... }` pagination as the
/// rest of the API. Load parsing is delegated to [LoadsRemoteDataSource] so a
/// saved load renders byte-for-byte like the market card.
///
/// The favorites payload shape is tolerated rather than assumed: a record may
/// nest the load under `load` / `load_data` / … or simply *be* the load. The
/// extraction below handles both so a backend naming choice can't blank the
/// list.
class SavedRemoteDataSource {
  SavedRemoteDataSource(this._dio, this._loads);

  final Dio _dio;
  final LoadsRemoteDataSource _loads;

  static const _path = '/favorites/';

  Future<List<SavedLoad>> getSaved() async {
    final res = await _dio.get<dynamic>(_path);
    return _resultsOf(res).map(_parseSaved).whereType<SavedLoad>().toList();
  }

  /// Saves a load via `POST /favorites/loads/{loadId}/` (no body). Favorites
  /// are keyed by the load id, so that id is also the un-save key — there is
  /// no separate favorite record to echo back. (`POST /favorites/` is 405; the
  /// create lives on the `loads/{id}/` sub-route.)
  Future<String?> addSaved(String loadId) async {
    await _dio.post<dynamic>('${_path}loads/$loadId/');
    return loadId;
  }

  /// Un-saves a load via `DELETE /favorites/loads/{loadId}/`.
  Future<void> removeSaved(String loadId) async {
    await _dio.delete<dynamic>('${_path}loads/$loadId/');
  }

  /// The caller's saved route ids, read from `GET /favorites/`. The favorites
  /// feed mixes loads and routes; route entries are picked out by [_routeIdOf]
  /// (load entries are skipped), so this is the un-save state for transports.
  Future<Set<String>> getSavedRouteIds() async {
    final res = await _dio.get<dynamic>(_path);
    final ids = <String>{};
    for (final record in _resultsOf(res)) {
      final id = _routeIdOf(record);
      if (id != null) ids.add(id);
    }
    return ids;
  }

  /// Saves a route (transport) via `POST /favorites/routes/{routeId}/`.
  Future<void> addSavedRoute(String routeId) async {
    await _dio.post<dynamic>('${_path}routes/$routeId/');
  }

  /// Un-saves a route via `DELETE /favorites/routes/{routeId}/`.
  Future<void> removeSavedRoute(String routeId) async {
    await _dio.delete<dynamic>('${_path}routes/$routeId/');
  }

  // ---------------------------------------------------------------------------
  // Parsing
  // ---------------------------------------------------------------------------

  SavedLoad? _parseSaved(Map<String, dynamic> record) {
    final loadMap = _loadMapOf(record);
    if (loadMap.isEmpty) return null;
    final load = _loads.parseLoad(loadMap);
    // Favorites are keyed by the load id (the DELETE route is
    // /favorites/loads/{load_id}/), so the load guid is the un-save key.
    return SavedLoad(id: load.guid, load: load);
  }

  /// The favorite may wrap the load under a nested key, or be the load itself.
  Map<String, dynamic> _loadMapOf(Map<String, dynamic> record) {
    // A `type`-tagged record is unambiguous: a route entry is never a load.
    final type = record['type']?.toString();
    if (type == 'route') return const {};

    const keys = [
      'item',
      'load',
      'load_data',
      'load_detail',
      'loads_id_data',
      'object',
      'content_object',
    ];
    for (final key in keys) {
      final v = record[key];
      if (v is Map) {
        final m = Map<String, dynamic>.from(v);
        // `item` is generic — only accept it when it actually looks like a
        // load (a route entry also nests its object under `item`).
        if (key == 'item' && !_looksLikeLoad(m)) continue;
        return m;
      }
    }
    // The record itself looks like a load when it carries route/owner fields.
    return _looksLikeLoad(record) ? record : const {};
  }

  bool _looksLikeLoad(Map<String, dynamic> m) {
    return m.containsKey('from_location') ||
        m.containsKey('pickup_region') ||
        m.containsKey('pickup_district') ||
        m.containsKey('pickup_country') ||
        m.containsKey('owner');
  }

  /// Extracts the route id from a favorites record that represents a saved
  /// route (vs a load). Loads are keyed by `load`; routes by `route`. Returns
  /// null when the record isn't a route, so load entries are skipped.
  String? _routeIdOf(Map<String, dynamic> record) {
    final type = record['type']?.toString();
    // Load entries are never routes — skip them.
    if (type == 'load') return null;

    for (final key in const ['route', 'route_data', 'route_detail', 'item']) {
      final v = record[key];
      if (v is Map) {
        // `item` is generic; only treat it as a route when the record is
        // tagged `route` or the object carries route-shaped fields.
        if (key == 'item' && type != 'route' && !_looksLikeRoute(v)) continue;
        final id = (v['id'] ?? v['guid'])?.toString().trim();
        if (id != null && id.isNotEmpty) return id;
      } else if (key != 'item' && v != null) {
        final id = v.toString().trim();
        if (id.isNotEmpty) return id;
      }
    }
    final fk = record['route_id'];
    if (fk != null) {
      final id = fk.toString().trim();
      if (id.isNotEmpty) return id;
    }
    // The record may *be* the route object (e.g. the `{ loads, routes }` shape,
    // where each route entry is the bare route tagged `type: route`).
    if (type == 'route' || _looksLikeRoute(record)) {
      final id = (record['id'] ?? record['guid'])?.toString().trim();
      if (id != null && id.isNotEmpty) return id;
    }
    return null;
  }

  /// Mirrors the web's `looksLikeRoute` heuristic for untagged favorite records.
  bool _looksLikeRoute(Map v) {
    return v.containsKey('truck') ||
        v.containsKey('truck_route') ||
        v.containsKey('departure_date') ||
        v.containsKey('arrival_date') ||
        v.containsKey('deadhead_radius_km');
  }

  // ---------------------------------------------------------------------------
  // Envelope helpers (same contract as loads / notifications)
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> _resultsOf(Response<dynamic> res) {
    final inner = _peel(res.data);

    // Shape A — split buckets: `{ loads: [...], routes: [...] }`. Tag each
    // entry with its `type` so the load/route splitters downstream can tell
    // them apart even when the entry is the bare object.
    if (inner is Map && (inner['loads'] is List || inner['routes'] is List)) {
      final out = <Map<String, dynamic>>[];
      for (final e in (inner['loads'] as List? ?? const [])) {
        if (e is Map) {
          out.add({...Map<String, dynamic>.from(e), 'type': 'load'});
        }
      }
      for (final e in (inner['routes'] as List? ?? const [])) {
        if (e is Map) {
          out.add({...Map<String, dynamic>.from(e), 'type': 'route'});
        }
      }
      return out;
    }

    // Shape B — flat paginated list of favorite records.
    final list = inner is List
        ? inner
        : (inner is Map
            ? (inner['results'] ?? inner['result'] ?? inner['favorites'])
            : null);
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
}
