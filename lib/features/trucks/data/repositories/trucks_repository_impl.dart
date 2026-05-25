import 'package:loadme_mobile/features/trucks/data/datasources/trucks_remote_data_source.dart';
import 'package:loadme_mobile/features/trucks/domain/entities/truck_entity.dart';
import 'package:loadme_mobile/features/trucks/domain/repositories/trucks_repository.dart';

class TrucksRepositoryImpl implements TrucksRepository {
  TrucksRepositoryImpl(this._remote);
  final TrucksRemoteDataSource _remote;

  @override
  Future<List<TruckEntity>> getTrucks({required int page, required int limit}) async {
    final response = await _remote.getTrucks(page: page, limit: limit);
    return response.result
        .map((e) => TruckEntity(guid: e.guid ?? '', fromAddress: e.fromAddress ?? '-', toAddress: e.toAddress ?? '-'))
        .toList();
  }
}
