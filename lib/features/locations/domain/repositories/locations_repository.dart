import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/features/locations/domain/entities/location_entity.dart';

abstract interface class LocationsRepository {
  /// Autocomplete the "Qayerdan / Qayerga" search against the public location
  /// directory. Returns countries, regions and districts matching [query].
  AsyncResult<List<LocationEntity>> search(String query, {int limit});

  /// Reverse-geocode a device GPS fix to the nearest directory place (drives
  /// "Mening joylashuvim"). Resolves to null when no place matches.
  AsyncResult<LocationEntity?> reverse({required double lat, required double lng});
}
