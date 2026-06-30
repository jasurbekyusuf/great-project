import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';

/// OpenStreetMap route preview — origin/destination pins + the driving route
/// between them.
///
/// Uses free OSM raster tiles (no API key) and the public OSRM demo server to
/// fetch the real road geometry from A → B. Until the route lands (or if the
/// request fails — offline, no road, an un-routable cross-border pair) it falls
/// back to a straight connecting line, so the preview always renders. Set
/// [interactive] = false to make it a static preview (e.g. inside a card that
/// opens a full-screen map).
class RouteMap extends StatefulWidget {
  const RouteMap({
    super.key,
    required this.from,
    required this.to,
    this.interactive = true,
  });

  final LatLng from;
  final LatLng to;
  final bool interactive;

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  /// Road geometry from OSRM; null until it resolves. The drawn line falls back
  /// to a straight from→to segment while this is null or on failure.
  List<LatLng>? _route;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void didUpdateWidget(RouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-fetch when either endpoint moves (e.g. the card rebuilds with resolved
    // backend coordinates).
    if (oldWidget.from != widget.from || oldWidget.to != widget.to) {
      _route = null;
      _loadRoute();
    }
  }

  Future<void> _loadRoute() async {
    // Identical endpoints have no route to draw.
    if (widget.from == widget.to) return;
    final points = await _fetchDrivingRoute(widget.from, widget.to);
    if (!mounted || points == null || points.isEmpty) return;
    setState(() => _route = points);
  }

  /// The polyline to draw — the road geometry once known, else the straight
  /// fallback so the line is never empty.
  List<LatLng> get _line => _route ?? [widget.from, widget.to];

  LatLng get _mid => LatLng(
        (widget.from.latitude + widget.to.latitude) / 2,
        (widget.from.longitude + widget.to.longitude) / 2,
      );

  // Rough zoom that keeps both endpoints in view based on their separation.
  double get _zoom {
    final dLat = (widget.from.latitude - widget.to.latitude).abs();
    final dLng = (widget.from.longitude - widget.to.longitude).abs();
    final span = dLat > dLng ? dLat : dLng;
    if (span > 30) return 3;
    if (span > 15) return 4;
    if (span > 7) return 5;
    if (span > 3) return 6;
    return 7;
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: _mid,
        initialZoom: _zoom,
        interactionOptions: InteractionOptions(
          flags:
              widget.interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.loadme_mobile',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: _line,
              color: FigmaPalette.primary,
              strokeWidth: 4,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: widget.from,
              width: 18,
              height: 18,
              child: const _Pin(filled: true),
            ),
            Marker(
              point: widget.to,
              width: 18,
              height: 18,
              child: const _Pin(filled: false),
            ),
          ],
        ),
      ],
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.filled});
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: filled ? FigmaPalette.primary : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: FigmaPalette.primary, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

/// Fetches the driving route geometry between [from] and [to] from the public
/// OSRM demo server (no API key). Returns the decoded polyline points, or null
/// when the request fails or no route exists — the caller then keeps the
/// straight-line fallback.
///
/// `geometries=geojson` returns `coordinates` as `[lng, lat]` pairs;
/// `overview=full` keeps the full-resolution geometry so the line hugs the road.
Future<List<LatLng>?> _fetchDrivingRoute(LatLng from, LatLng to) async {
  try {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
    ));
    final res = await dio.get<dynamic>(
      'https://router.project-osrm.org/route/v1/driving/'
      '${from.longitude},${from.latitude};${to.longitude},${to.latitude}',
      queryParameters: const {'overview': 'full', 'geometries': 'geojson'},
    );
    final data = res.data;
    if (data is! Map || data['code'] != 'Ok') return null;
    final routes = data['routes'];
    if (routes is! List || routes.isEmpty) return null;
    final coords = routes.first['geometry']?['coordinates'];
    if (coords is! List) return null;
    final points = <LatLng>[];
    for (final c in coords) {
      if (c is List && c.length >= 2) {
        final lng = (c[0] as num).toDouble();
        final lat = (c[1] as num).toDouble();
        points.add(LatLng(lat, lng));
      }
    }
    return points.length >= 2 ? points : null;
  } catch (_) {
    return null;
  }
}

/// Demo coordinate lookup for the sample city names. Falls back to Tashkent.
LatLng cityLatLng(String city) =>
    _coords[city.trim().toLowerCase()] ?? _tashkent;

/// Resolves a full "District, Region" address to a coordinate.
///
/// `cityLatLng(addressCity(...))` only ever tried the *district* token (the
/// first segment, e.g. "Chilonzor"), which is not in the lookup — so both
/// endpoints collapsed to Tashkent and no route line was drawn. This walks
/// every comma-separated token (district first, then region) and returns the
/// first hit, so an inter-region route still renders even when the backend
/// omits precise pickup/delivery coordinates.
LatLng resolveAddressLatLng(String address) {
  for (final part in address.split(',')) {
    final hit = _coords[part.trim().toLowerCase()];
    if (hit != null) return hit;
  }
  return _tashkent;
}

const _tashkent = LatLng(41.2995, 69.2401);

const Map<String, LatLng> _coords = {
  'shahrisabz': LatLng(39.0578, 66.8331),
  'toshkent': _tashkent,
  'tashkent': _tashkent,
  'samarqand': LatLng(39.6542, 66.9597),
  'buxoro': LatLng(39.7747, 64.4286),
  'farg‘ona': LatLng(40.3864, 71.7864),
  "farg'ona": LatLng(40.3864, 71.7864),
  'namangan': LatLng(40.9983, 71.6726),
  'andijon': LatLng(40.7821, 72.3442),
  'qarshi': LatLng(38.8606, 65.7891),
  'nukus': LatLng(42.4731, 59.6103),
  'ostona': LatLng(51.1605, 71.4704),
  'astana': LatLng(51.1605, 71.4704),
  'orenburg': LatLng(51.7682, 55.0969),
  'almaty': LatLng(43.2220, 76.8512),
  'shymkent': LatLng(42.3417, 69.5901),
  'samara': LatLng(53.1959, 50.1002),
  'bishkek': LatLng(42.8746, 74.5698),
  'dushanbe': LatLng(38.5598, 68.7870),
  'xiva': LatLng(41.3783, 60.3639),
  'petropavlovsk-kamchatskiy': LatLng(53.0445, 158.6475),
};
