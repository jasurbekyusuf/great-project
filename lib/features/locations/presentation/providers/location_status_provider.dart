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

/// Best-effort "turn location on" flow for the banner. The *service* (GPS) being
/// off is checked first — that opens the device location settings, never the
/// App-info page — then permission: a denied permission is re-requested in-app
/// (the OS dialog), and only a *permanent* denial, which has no in-app path,
/// falls back to the app settings page. Re-checks [locationEnabledProvider]
/// afterwards so the banner clears the moment access is granted.
Future<void> enableLocation(WidgetRef ref) async {
  try {
    // GPS off is the most common — and most easily fixed — cause of the banner.
    // Send the user to the location toggle, not the confusing App-info page.
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
    } else {
      // Service is on, so it's a permission gap. A first-time/denied permission
      // can still be requested in-app; the app settings page is a last resort
      // reserved for a permanent denial (the OS won't show the dialog again).
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
      }
    }
  } catch (_) {
    // Never let a settings-launch failure crash the marketplace.
  }
  ref.invalidate(locationEnabledProvider);
}
