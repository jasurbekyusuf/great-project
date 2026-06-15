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
