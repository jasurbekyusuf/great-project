import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';

/// OpenStreetMap route preview — origin/destination pins + a connecting line.
///
/// Uses free OSM raster tiles (no API key). Set [interactive] = false to make
/// it a static preview (e.g. inside a card that opens a full-screen map).
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
              points: [widget.from, widget.to],
              color: FigmaPalette.primary,
              strokeWidth: 3,
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

/// Demo coordinate lookup for the sample city names. Falls back to Tashkent.
LatLng cityLatLng(String city) =>
    _coords[city.trim().toLowerCase()] ?? _tashkent;

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
