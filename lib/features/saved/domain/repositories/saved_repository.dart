import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/features/saved/domain/entities/saved_load.dart';

/// The user's saved/favorited loads ("Saqlanganlar"). Identity is the bearer
/// token attached by the shared Dio interceptor; every endpoint is authed.
///
/// Backed by the DRF favorites resource (favorites are keyed by the load id):
/// * `GET    /favorites/`              — the caller's saved loads + routes
/// * `POST   /favorites/loads/{id}/`   — save a load
/// * `DELETE /favorites/loads/{id}/`   — un-save a load
/// * `POST   /favorites/routes/{id}/`  — save a route (transport)
/// * `DELETE /favorites/routes/{id}/`  — un-save a route
abstract interface class SavedRepository {
  AsyncResult<List<SavedLoad>> getSaved();

  /// Saves [loadId]. Resolves to the load id, which is the un-save key.
  AsyncResult<String?> addSaved(String loadId);

  /// Un-saves the load with id [loadId].
  AsyncResult<void> removeSaved(String loadId);

  /// The caller's saved route ids (transport favorites).
  AsyncResult<Set<String>> getSavedRouteIds();

  /// Saves the route with id [routeId].
  AsyncResult<void> addSavedRoute(String routeId);

  /// Un-saves the route with id [routeId].
  AsyncResult<void> removeSavedRoute(String routeId);
}
