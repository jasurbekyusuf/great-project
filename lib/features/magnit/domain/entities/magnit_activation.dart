/// Outcome of `POST /trucks/routes/magnet/`.
///
/// The endpoint either creates the auto-route ([activated], with the new
/// [MagnitActivation.routeId]) or replies `200 {status: 'truck_required'}`
/// ([truckRequired]) — meaning the carrier has no truck of the chosen type yet
/// and must add one before the magnet can watch for matching loads.
enum MagnitStatus { activated, truckRequired }

class MagnitActivation {
  const MagnitActivation({required this.status, this.routeId});

  final MagnitStatus status;
  final String? routeId;
}
