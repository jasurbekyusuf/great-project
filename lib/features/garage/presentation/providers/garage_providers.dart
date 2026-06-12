import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A vehicle parked in the user's garage — shown on the "Transportlar" tab.
class GarageVehicle {
  const GarageVehicle({
    required this.id,
    required this.name,
    required this.model,
    required this.plate,
    this.photoUrl,
  });

  final String id;
  final String name; // e.g. "Isuzu Katta"
  final String model; // e.g. "Isuzu FVR 33"
  final String plate; // e.g. "30 A 701 AS"
  final String? photoUrl;
}

/// A saved route the carrier offers — shown on the "Yo'nalishlarim" tab.
class GarageRoute {
  const GarageRoute({
    required this.id,
    required this.name,
    required this.priceLabel,
    required this.fromCity,
    required this.fromCountry,
    required this.toCity,
    required this.toCountry,
    required this.distanceKm,
    required this.weightT,
    required this.loadKind,
    required this.active,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String priceLabel;
  final String fromCity;
  final String fromCountry;
  final String toCity;
  final String toCountry;
  final int distanceKm;
  final double weightT;
  final String loadKind;
  final bool active;
  final String? avatarUrl;

  GarageRoute copyWith({bool? active}) => GarageRoute(
        id: id,
        name: name,
        priceLabel: priceLabel,
        fromCity: fromCity,
        fromCountry: fromCountry,
        toCity: toCity,
        toCountry: toCountry,
        distanceKm: distanceKm,
        weightT: weightT,
        loadKind: loadKind,
        active: active ?? this.active,
        avatarUrl: avatarUrl,
      );
}

// Demo seed data until the garage backend is wired. Mirrors the fake data
// sources used elsewhere in the app so the UI is fully data-driven.
const _seedVehicles = <GarageVehicle>[
  GarageVehicle(id: 'v1', name: 'Isuzu Katta', model: 'Isuzu FVR 33', plate: '30 A 701 AS'),
  GarageVehicle(id: 'v2', name: 'Isuzu Katta', model: 'Isuzu FVR 33', plate: '30 A 702 AA'),
];

const _seedRoutes = <GarageRoute>[
  GarageRoute(
    id: 'r1',
    name: 'Isuzu Katta',
    priceLabel: '20 000 000 so’m',
    fromCity: 'Shahrisabz',
    fromCountry: 'UZB',
    toCity: 'Ostona',
    toCountry: 'KZ',
    distanceKm: 328,
    weightT: 33,
    loadKind: 'To’liq',
    active: true,
  ),
  GarageRoute(
    id: 'r2',
    name: 'Isuzu Katta',
    priceLabel: '20 000 000 so’m',
    fromCity: 'Shahrisabz',
    fromCountry: 'UZB',
    toCity: 'Ostona',
    toCountry: 'KZ',
    distanceKm: 328,
    weightT: 33,
    loadKind: 'To’liq',
    active: false,
  ),
];

final garageVehiclesProvider =
    Provider<List<GarageVehicle>>((ref) => _seedVehicles);

/// Holds the saved routes and the per-route active/paused toggle state.
class GarageRoutesNotifier extends Notifier<List<GarageRoute>> {
  @override
  List<GarageRoute> build() => _seedRoutes;

  void toggleActive(String id) {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(active: !r.active) else r,
    ];
  }

  void remove(String id) {
    state = [
      for (final r in state)
        if (r.id != id) r,
    ];
  }
}

final garageRoutesProvider =
    NotifierProvider<GarageRoutesNotifier, List<GarageRoute>>(
  GarageRoutesNotifier.new,
);
