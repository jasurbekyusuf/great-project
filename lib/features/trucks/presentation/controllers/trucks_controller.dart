import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/network/dio_client.dart';
import 'package:loadme_mobile/features/trucks/data/datasources/trucks_remote_data_source.dart';
import 'package:loadme_mobile/features/trucks/data/repositories/trucks_repository_impl.dart';
import 'package:loadme_mobile/features/trucks/domain/entities/truck_entity.dart';
import 'package:loadme_mobile/features/trucks/domain/repositories/trucks_repository.dart';

final trucksRepositoryProvider = Provider<TrucksRepository>(
  (ref) => TrucksRepositoryImpl(TrucksRemoteDataSource(ref.watch(dioProvider))),
);

final trucksControllerProvider = AutoDisposeAsyncNotifierProvider<TrucksController, List<TruckEntity>>(TrucksController.new);

class TrucksController extends AutoDisposeAsyncNotifier<List<TruckEntity>> {
  @override
  Future<List<TruckEntity>> build() {
    return ref.read(trucksRepositoryProvider).getTrucks(page: 1, limit: 10);
  }
}
