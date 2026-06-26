/// A truck type from `GET /trucks/types/`.
///
/// The magnet endpoint (`POST /trucks/routes/magnet/`) wants a `truck_type`
/// UUID, so the picker carries the [id] alongside the human-readable [name].
class MagnitTruckType {
  const MagnitTruckType({required this.id, required this.name});

  final String id;
  final String name;
}
