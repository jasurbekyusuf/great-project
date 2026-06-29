import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/features/auth/presentation/providers/current_user_provider.dart';

/// Post-registration location primer ("Lokatsiyaga ruxsat bering").
///
/// Shows a map with the user's approximate position highlighted, explains why
/// we need location ("…so we can find the nearest loads for you"), then on
/// "Tushunarli" asks the OS for the permission and continues to the role-aware
/// home. We always proceed afterwards so the user is never stuck on this gate.
class LocationPermissionScreen extends ConsumerStatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  ConsumerState<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState
    extends ConsumerState<LocationPermissionScreen> {
  static const _center = LatLng(41.2995, 69.2401); // Tashkent
  bool _busy = false;

  Future<void> _allowAndContinue() async {
    if (_busy) return;
    setState(() => _busy = true);
    // Best-effort OS prompt — we continue regardless of the user's choice so
    // they are never trapped on this screen.
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
    } catch (_) {
      // Ignore — never block entry to the app on a permission failure.
    }
    if (!mounted) return;
    setState(() => _busy = false);
    final role = ref.read(currentUserRoleSyncProvider);
    context.go(role == 'carrier' ? '/loads' : '/trucks');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(child: _MapPreview(center: _center)),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                children: [
                  Text(
                    'location.permTitle'.tr(ref),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      height: 32 / 24,
                      fontWeight: FontWeight.w700,
                      color: FigmaPalette.countLabel,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'location.permBody'.tr(ref),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 24 / 16,
                      fontWeight: FontWeight.w400,
                      color: FigmaPalette.inkBody,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: Material(
                  color: FigmaPalette.primary,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: _busy ? null : _allowAndContinue,
                    borderRadius: BorderRadius.circular(14),
                    child: Center(
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'location.permUnderstood'.tr(ref),
                              style: const TextStyle(
                                fontSize: 14,
                                height: 20 / 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A non-interactive OSM map card with a translucent geofence circle and a
/// centred "your location" dot — a clean stand-in for the Figma map mock.
class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.center});
  final LatLng center;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 12,
            interactionOptions:
                const InteractionOptions(flags: InteractiveFlag.none),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.loadme_mobile',
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: center,
                  radius: 72,
                  color: const Color(0x26004EEB), // primary @ ~15%
                  borderColor: FigmaPalette.primary,
                  borderStrokeWidth: 2,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 22,
                  height: 22,
                  child: const _LocationDot(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationDot extends StatelessWidget {
  const _LocationDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FigmaPalette.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
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
