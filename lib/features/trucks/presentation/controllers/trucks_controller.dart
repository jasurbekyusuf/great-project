import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/config/env/app_env.dart';
import 'package:loadme_mobile/core/network/dio_client.dart';
import 'package:loadme_mobile/features/trucks/data/datasources/fake_trucks_remote_data_source.dart';
import 'package:loadme_mobile/features/trucks/data/datasources/trucks_remote_data_source.dart';
import 'package:loadme_mobile/features/trucks/data/repositories/trucks_repository_impl.dart';
import 'package:loadme_mobile/features/trucks/domain/entities/truck_detail_entity.dart';
import 'package:loadme_mobile/features/trucks/domain/entities/truck_entity.dart';
import 'package:loadme_mobile/features/trucks/domain/repositories/trucks_repository.dart';

final trucksRepositoryProvider = Provider<TrucksRepository>((ref) {
  final useFake = ref.watch(appEnvProvider).useFakeData;
  final ds = useFake ? FakeTrucksRemoteDataSource() : TrucksRemoteDataSource(ref.watch(dioProvider));
  return TrucksRepositoryImpl(ds);
});

final trucksControllerProvider =
    AutoDisposeAsyncNotifierProvider<TrucksController, List<TruckEntity>>(
        TrucksController.new);
final myTrucksControllerProvider =
    AutoDisposeAsyncNotifierProvider<MyTrucksController, List<TruckEntity>>(
        MyTrucksController.new);
final truckDetailsProvider =
    FutureProvider.family.autoDispose<TruckDetailEntity, String>((ref, id) {
  return ref.read(trucksRepositoryProvider).getTruckById(id);
});

enum MyTrucksTab { available, myTrucks, history }

class TrucksController extends AutoDisposeAsyncNotifier<List<TruckEntity>> {
  @override
  Future<List<TruckEntity>> build() {
    return ref.read(trucksRepositoryProvider).getTrucks(page: 1, limit: 10);
  }
}

class MyTrucksController extends AutoDisposeAsyncNotifier<List<TruckEntity>> {
  int _page = 1;
  static const _limit = 10;
  MyTrucksTab _tab = MyTrucksTab.available;

  MyTrucksTab get tab => _tab;

  @override
  Future<List<TruckEntity>> build() => _fetch();

  Future<void> setTab(MyTrucksTab tab) async {
    if (_tab == tab) return;
    _tab = tab;
    await refresh();
  }

  Future<void> refresh() async {
    _page = 1;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<List<TruckEntity>> _fetch() {
    final repo = ref.read(trucksRepositoryProvider);
    return switch (_tab) {
      MyTrucksTab.available =>
        repo.getMyPostTrucks(page: _page, limit: _limit, isActive: true),
      MyTrucksTab.myTrucks => repo.getMyTrucks(page: _page, limit: _limit),
      MyTrucksTab.history =>
        repo.getMyPostTrucks(page: _page, limit: _limit, isActive: false),
    };
  }

  Future<void> updateCurrentItemStatus({
    required String guid,
    required bool isActive,
  }) async {
    final repo = ref.read(trucksRepositoryProvider);
    if (_tab == MyTrucksTab.myTrucks) {
      await repo.updateTruckStatus(guid: guid, isActive: isActive);
    } else {
      await repo.updatePostTruckStatus(guid: guid, isActive: isActive);
    }
    await refresh();
  }

  Future<void> updateTruckStatus({
    required String guid,
    required bool isActive,
  }) async {
    await ref
        .read(trucksRepositoryProvider)
        .updateTruckStatus(guid: guid, isActive: isActive);
    await refresh();
  }

  Future<void> updatePostTruckStatus({
    required String guid,
    required bool isActive,
  }) async {
    await ref
        .read(trucksRepositoryProvider)
        .updatePostTruckStatus(guid: guid, isActive: isActive);
    await refresh();
  }
}
