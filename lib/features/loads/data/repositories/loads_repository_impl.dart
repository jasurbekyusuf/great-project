import 'package:loadme_mobile/features/loads/data/datasources/loads_remote_data_source.dart';
import 'package:loadme_mobile/features/loads/domain/entities/load_entity.dart';
import 'package:loadme_mobile/features/loads/domain/repositories/loads_repository.dart';

class LoadsRepositoryImpl implements LoadsRepository {
  LoadsRepositoryImpl(this._remote);

  final LoadsRemoteDataSource _remote;

  @override
  Future<List<LoadEntity>> getLoads({required int page, required int limit}) async {
    final response = await _remote.getLoads(page: page, limit: limit);
    return response.result
        .map((e) => LoadEntity(
              guid: e.guid ?? '',
              fromAddress: e.fromAddress ?? '-',
              toAddress: e.toAddress ?? '-',
              comment: e.comment,
              pickupDate: e.pickupDate,
              price: e.price?.toDouble(),
            ))
        .toList();
  }

  @override
  Future<LoadEntity> getLoadById(String id) async {
    final e = await _remote.getLoadById(id);
    return LoadEntity(
      guid: e.guid ?? '',
      fromAddress: e.fromAddress ?? '-',
      toAddress: e.toAddress ?? '-',
      comment: e.comment,
      pickupDate: e.pickupDate,
      price: e.price?.toDouble(),
    );
  }

  @override
  Future<void> addLoad({
    required String fromAddress,
    required String toAddress,
    required String comment,
  }) {
    return _remote.addLoad(fromAddress: fromAddress, toAddress: toAddress, comment: comment);
  }

  @override
  Future<void> updateLoad({
    required String loadId,
    required String fromAddress,
    required String toAddress,
    required String comment,
  }) {
    return _remote.updateLoad(
      loadId: loadId,
      fromAddress: fromAddress,
      toAddress: toAddress,
      comment: comment,
    );
  }
}
