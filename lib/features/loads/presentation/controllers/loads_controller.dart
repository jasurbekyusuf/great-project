import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/config/env/app_env.dart';
import 'package:loadme_mobile/core/network/dio_client.dart';
import 'package:loadme_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:loadme_mobile/features/loads/data/datasources/fake_loads_remote_data_source.dart';
import 'package:loadme_mobile/features/loads/data/datasources/loads_remote_data_source.dart';
import 'package:loadme_mobile/features/loads/data/repositories/loads_repository_impl.dart';
import 'package:loadme_mobile/features/loads/domain/entities/load_entity.dart';
import 'package:loadme_mobile/features/loads/domain/repositories/loads_repository.dart';

final loadsRepositoryProvider = Provider<LoadsRepository>((ref) {
  final useFake = ref.watch(appEnvProvider).useFakeData;
  final ds = useFake ? FakeLoadsRemoteDataSource() : LoadsRemoteDataSource(ref.watch(dioProvider));
  return LoadsRepositoryImpl(ds);
});

final loadsControllerProvider =
    AutoDisposeAsyncNotifierProvider<LoadsController, List<LoadEntity>>(
        LoadsController.new);
final loadDetailsProvider =
    FutureProvider.family.autoDispose<LoadEntity, String>((ref, id) {
  return ref.read(loadsRepositoryProvider).getLoadById(id);
});
final myLoadsControllerProvider =
    AutoDisposeAsyncNotifierProvider<MyLoadsController, List<LoadEntity>>(
        MyLoadsController.new);

enum MyLoadsTab { active, history }

class LoadsController extends AutoDisposeAsyncNotifier<List<LoadEntity>> {
  int _page = 1;
  static const _limit = 10;
  String? _query;

  @override
  Future<List<LoadEntity>> build() async {
    final list = await ref
        .read(loadsRepositoryProvider)
        .getLoads(page: _page, limit: _limit);
    return _applyFilter(list);
  }

  Future<void> refresh() async {
    _page = 1;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final list = await ref
          .read(loadsRepositoryProvider)
          .getLoads(page: _page, limit: _limit);
      return _applyFilter(list);
    });
  }

  void applyQuery(String query) {
    _query = query.trim().isEmpty ? null : query.trim().toLowerCase();
    final current = state.valueOrNull ?? const <LoadEntity>[];
    state = AsyncData(_applyFilter(current));
  }

  Future<void> saveLoad({
    String? loadId,
    required String fromAddress,
    required String toAddress,
    required String comment,
  }) async {
    if (loadId == null) {
      await ref.read(loadsRepositoryProvider).addLoad(
          fromAddress: fromAddress, toAddress: toAddress, comment: comment);
    } else {
      await ref.read(loadsRepositoryProvider).updateLoad(
            loadId: loadId,
            fromAddress: fromAddress,
            toAddress: toAddress,
            comment: comment,
          );
    }
    await refresh();
  }

  Future<void> updateStatus({
    required String guid,
    required bool isActive,
    String? closedPlatform,
  }) async {
    await ref.read(loadsRepositoryProvider).updateLoadStatus(
          guid: guid,
          isActive: isActive,
          closedPlatform: closedPlatform,
        );
    await refresh();
  }

  List<LoadEntity> _applyFilter(List<LoadEntity> input) {
    if (_query == null) return input;
    return input
        .where((e) =>
            e.fromAddress.toLowerCase().contains(_query!) ||
            e.toAddress.toLowerCase().contains(_query!))
        .toList();
  }
}

class MyLoadsController extends AutoDisposeAsyncNotifier<List<LoadEntity>> {
  int _page = 1;
  static const _limit = 10;
  MyLoadsTab _tab = MyLoadsTab.active;

  MyLoadsTab get tab => _tab;

  @override
  Future<List<LoadEntity>> build() => _fetch();

  Future<void> setTab(MyLoadsTab tab) async {
    if (_tab == tab) return;
    _tab = tab;
    await refresh();
  }

  Future<void> refresh() async {
    _page = 1;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<List<LoadEntity>> _fetch() {
    final session = ref.read(authControllerProvider).valueOrNull;
    return ref.read(loadsRepositoryProvider).getMyLoads(
          page: _page,
          limit: _limit,
          isActive: _tab == MyLoadsTab.active,
          userGuid: session?.userGuid,
        );
  }

  Future<void> updateStatus({
    required String guid,
    required bool isActive,
    String? closedPlatform,
  }) async {
    await ref.read(loadsRepositoryProvider).updateLoadStatus(
          guid: guid,
          isActive: isActive,
          closedPlatform: closedPlatform,
        );
    await refresh();
  }
}
