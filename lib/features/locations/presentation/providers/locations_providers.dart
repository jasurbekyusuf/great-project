import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:loadme_mobile/core/logging/app_logger.dart';
import 'package:loadme_mobile/core/network/dio_client.dart';
import 'package:loadme_mobile/features/locations/data/datasources/locations_remote_data_source.dart';
import 'package:loadme_mobile/features/locations/data/repositories/locations_repository_impl.dart';
import 'package:loadme_mobile/features/locations/domain/entities/location_entity.dart';
import 'package:loadme_mobile/features/locations/domain/repositories/locations_repository.dart';

final locationsRepositoryProvider = Provider<LocationsRepository>(
  (ref) => LocationsRepositoryImpl(
      LocationsRemoteDataSource(ref.watch(dioProvider))),
);

/// Debounced location autocomplete for the "Qayerdan / Qayerga" search.
///
/// Keyed by the raw query string: each distinct query is its own
/// auto-disposed request that fires 300 ms after typing settles, so a burst of
/// keystrokes makes at most one network call (the intermediate keys are
/// disposed during their debounce window and bail out before hitting the API).
final locationSearchProvider = FutureProvider.family
    .autoDispose<List<LocationEntity>, String>((ref, query) async {
  final q = query.trim();
  if (q.isEmpty) return const <LocationEntity>[];

  // Debounce: if the user keeps typing, this key is disposed during the wait —
  // skip the call rather than racing a result the UI no longer wants.
  var active = true;
  ref.onDispose(() => active = false);
  await Future<void>.delayed(const Duration(milliseconds: 300));
  if (!active) return const <LocationEntity>[];

  final result = await ref.read(locationsRepositoryProvider).search(q);
  return result.fold((f) => throw f, (list) => list);
});

/// Reads the device's current GPS fix as raw `(lat, lng)` — the anchor point for
/// the radius / "nearest-first" load filter (`pickup_anchor=lat,lng` on
/// `/loads/available/`, per the backend contract where the anchor is the user's
/// standing location).
///
/// Runs the permission prompt when needed and returns null — so the caller can
/// fall back to an unanchored query — when permission is denied, the service is
/// off, or the fix times out. Never throws.
Future<({double lat, double lng})?> currentDeviceLatLng() async {
  final log = AppLogger.tagged('GPS');
  try {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    log.i('permission=$perm');
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return null;
    }
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    log.i('serviceEnabled=$serviceOn');
    if (!serviceOn) return null;

    // Last-known fix first: it returns instantly on any real device and
    // city-level accuracy is all the reverse-geocode lookup needs. This keeps
    // "Mening joylashuvim" from hanging on a cold-GPS acquisition (the spinner
    // that never resolved). Only when there's no cached fix do we wait for a
    // fresh one.
    //
    // `forceAndroidLocationManager: true` reads the platform LocationManager
    // (GPS_PROVIDER) instead of the fused Google-Play-Services provider. The
    // Android emulator injects its set location into the GPS provider, but the
    // fused provider never receives it — which is why the fused path always
    // timed out on the emulator. The raw provider also works fine on real
    // devices, so this is a strict improvement.
    final last =
        await Geolocator.getLastKnownPosition(forceAndroidLocationManager: true);
    if (last != null) {
      log.i('lastKnown -> lat=${last.latitude} lng=${last.longitude}');
      return (lat: last.latitude, lng: last.longitude);
    }
    log.i('lastKnown=null, requesting fresh fix…');

    // On Android force the LocationManager for the same emulator/raw-provider
    // reason; elsewhere use the platform-default settings.
    final settings = Platform.isAndroid
        ? AndroidSettings(
            accuracy: LocationAccuracy.low,
            forceLocationManager: true,
            timeLimit: const Duration(seconds: 10),
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 10),
          );

    try {
      final pos =
          await Geolocator.getCurrentPosition(locationSettings: settings);
      log.i('currentPosition -> lat=${pos.latitude} lng=${pos.longitude}');
      return (lat: pos.latitude, lng: pos.longitude);
    } catch (e) {
      // A live fix can still time out (cold GPS, or an emulator with no route).
      // Try the cache one last time before giving up.
      log.w('getCurrentPosition failed: $e — retrying lastKnown');
      final retry = await Geolocator.getLastKnownPosition(
          forceAndroidLocationManager: true);
      if (retry != null) {
        log.i('lastKnown(retry) -> lat=${retry.latitude} lng=${retry.longitude}');
        return (lat: retry.latitude, lng: retry.longitude);
      }
      log.w('no fix available, returning null');
      return null;
    }
  } catch (e) {
    log.e('currentDeviceLatLng error: $e');
    return null;
  }
}

/// Resolves the device's current GPS position to a directory place (via
/// `/locations/reverse/`) for the pickup sheet's "Mening joylashuvim" action.
///
/// Returns null — so the caller can fall back to manual search or kick off the
/// permission/settings flow — when location permission is denied, the service
/// is off, the fix times out, or the backend can't match the coordinates. Never
/// throws: any failure collapses to null.
Future<LocationEntity?> resolveCurrentLocation(WidgetRef ref) async {
  try {
    final coords = await currentDeviceLatLng();
    if (coords == null) return null;
    final result = await ref
        .read(locationsRepositoryProvider)
        .reverse(lat: coords.lat, lng: coords.lng);
    return result.fold((_) => null, (place) => place);
  } catch (_) {
    return null;
  }
}
