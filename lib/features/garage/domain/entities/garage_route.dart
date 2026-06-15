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
