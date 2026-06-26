import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Whether the device can give us a position right now — the location service
/// is on AND the app holds a while-in-use/always permission. Drives the
/// marketplace "joylashuvni yoqing" banner: it shows only when this resolves to
/// `false`. Any geolocator error resolves to `true` so a platform hiccup never
/// nags the user with a false warning.
final locationEnabledProvider = FutureProvider.autoDispose<bool>((ref) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    final perm = await Geolocator.checkPermission();
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  } catch (_) {
    return true;
  }
});

/// Best-effort "turn location on" flow for the banner: ask for permission, and
/// if it's permanently denied or the service is off, bounce the user to the
/// relevant settings page. Re-checks [locationEnabledProvider] afterwards so the
/// banner clears the moment access is granted.
Future<void> enableLocation(WidgetRef ref) async {
  try {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    } else if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
    }
  } catch (_) {
    // Never let a settings-launch failure crash the marketplace.
  }
  ref.invalidate(locationEnabledProvider);
}
