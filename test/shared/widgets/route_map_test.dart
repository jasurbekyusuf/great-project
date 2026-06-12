import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:loadme_mobile/shared/widgets/route_map.dart';

// NOTE: a full widget pump of RouteMap can't run in the test sandbox because
// flutter_map fetches OSM tiles over the network (blocked → HTTP 400). The
// camera-fit / layout logic is exercised on-device. Here we cover the pure
// coordinate lookup.
void main() {
  test('cityLatLng resolves known cities and falls back to Tashkent', () {
    expect(cityLatLng('Shahrisabz').latitude, closeTo(39.0578, 0.01));
    expect(cityLatLng('Ostona'), const LatLng(51.1605, 71.4704));
    expect(cityLatLng('Unknown City'), const LatLng(41.2995, 69.2401));
  });
}
