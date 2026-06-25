import 'package:loadme_mobile/core/result/guard.dart';
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/features/locations/data/datasources/locations_remote_data_source.dart';
import 'package:loadme_mobile/features/locations/domain/entities/location_entity.dart';
import 'package:loadme_mobile/features/locations/domain/repositories/locations_repository.dart';

class LocationsRepositoryImpl implements LocationsRepository {
  LocationsRepositoryImpl(this._remote);

  final LocationsRemoteDataSource _remote;
  static const _tag = 'LocationsRepository';

  @override
  AsyncResult<List<LocationEntity>> search(String query, {int limit = 20}) =>
      Guard.run(() => _remote.search(query, limit: limit), tag: _tag);
}
