/// A vehicle parked in the user's garage — shown on the "Transportlar" tab.
class GarageVehicle {
  const GarageVehicle({
    required this.id,
    required this.name,
    required this.model,
    required this.plate,
    this.photoUrl,
    this.truckTypeId,
    this.truckModelId,
    this.measurementValue,
    this.measurementUnit,
  });

  final String id;
  final String name; // e.g. "Isuzu Katta"
  final String model; // e.g. "Isuzu FVR 33"
  final String plate; // e.g. "30 A 701 AS"
  final String? photoUrl;

  // Create-only fields (`POST /trucks/`): the backend wants a `truck_type`
  // UUID plus a capacity split into value + unit. They are null when the
  // vehicle was parsed from a list/detail response (read path).
  final String? truckTypeId; // truck_type UUID from `GET /trucks/types/`
  final String? truckModelId; // truck_model UUID from `GET /trucks/models/`
  final String? measurementValue; // e.g. "8.5"
  final String? measurementUnit; // "ton" | "m3"
}
