import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/config/env/app_env.dart';
import 'package:loadme_mobile/core/errors/app_failure.dart';
import 'package:loadme_mobile/core/network/dio_client.dart';
import 'package:loadme_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:loadme_mobile/features/loads/data/datasources/fake_loads_remote_data_source.dart';
import 'package:loadme_mobile/features/loads/data/datasources/loads_remote_data_source.dart';
import 'package:loadme_mobile/features/loads/data/repositories/loads_repository_impl.dart';
import 'package:loadme_mobile/features/loads/domain/entities/load_entity.dart';
import 'package:loadme_mobile/features/loads/domain/repositories/loads_repository.dart';
import 'package:loadme_mobile/features/loads/domain/use_cases/loads_use_cases.dart';

// -----------------------------------------------------------------------------
// DI wiring
// -----------------------------------------------------------------------------

final loadsRepositoryProvider = Provider<LoadsRepository>((ref) {
  final useFake = ref.watch(appEnvProvider).useFakeData;
  final ds = useFake
      ? FakeLoadsRemoteDataSource()
      : LoadsRemoteDataSource(ref.watch(dioProvider));
  return LoadsRepositoryImpl(ds);
});

final fetchLoadsUseCaseProvider =
    Provider((ref) => FetchLoadsUseCase(ref.watch(loadsRepositoryProvider)));
final fetchMyLoadsUseCaseProvider =
    Provider((ref) => FetchMyLoadsUseCase(ref.watch(loadsRepositoryProvider)));
final fetchLoadByIdUseCaseProvider =
    Provider((ref) => FetchLoadByIdUseCase(ref.watch(loadsRepositoryProvider)));
final saveLoadUseCaseProvider =
    Provider((ref) => SaveLoadUseCase(ref.watch(loadsRepositoryProvider)));
final updateLoadStatusUseCaseProvider =
    Provider((ref) => UpdateLoadStatusUseCase(ref.watch(loadsRepositoryProvider)));

// Async family for load detail page.
final loadDetailsProvider =
    FutureProvider.family.autoDispose<LoadEntity, String>((ref, id) async {
  final result = await ref.read(fetchLoadByIdUseCaseProvider).call(id);
  return result.fold((f) => throw f, (e) => e);
});

// -----------------------------------------------------------------------------
// Controllers
// -----------------------------------------------------------------------------

final loadsControllerProvider =
    AutoDisposeAsyncNotifierProvider<LoadsController, List<LoadEntity>>(
        LoadsController.new);

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
    final result = await ref
        .read(fetchLoadsUseCaseProvider)
        .call(const PaginatedInput());
    return result.fold(
      (f) => throw f,
      (list) => _applyFilter(list),
    );
  }

  Future<void> refresh() async {
    _page = 1;
    state = const AsyncLoading();
    final result = await ref
        .read(fetchLoadsUseCaseProvider)
        .call(PaginatedInput(page: _page, limit: _limit));
    state = result.fold(
      (f) => AsyncError(f, StackTrace.current),
      (list) => AsyncData(_applyFilter(list)),
    );
  }

  void applyQuery(String query) {
    _query = query.trim().isEmpty ? null : query.trim().toLowerCase();
    final current = state.valueOrNull ?? const <LoadEntity>[];
    state = AsyncData(_applyFilter(current));
  }

  Future<AppFailure?> saveLoad({
    String? loadId,
    required String fromAddress,
    required String toAddress,
    required String comment,
  }) async {
    final result = await ref.read(saveLoadUseCaseProvider).call(
          SaveLoadInput(
            loadId: loadId,
            fromAddress: fromAddress,
            toAddress: toAddress,
            comment: comment,
          ),
        );
    return result.fold((f) => f, (_) {
      refresh();
      return null;
    });
  }

  Future<AppFailure?> updateStatus({
    required String guid,
    required bool isActive,
    String? closedPlatform,
  }) async {
    final result = await ref.read(updateLoadStatusUseCaseProvider).call(
          UpdateLoadStatusInput(
            guid: guid,
            isActive: isActive,
            closedPlatform: closedPlatform,
          ),
        );
    return result.fold((f) => f, (_) {
      refresh();
      return null;
    });
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
    final list = await _fetch();
    state = AsyncData(list);
  }

  Future<List<LoadEntity>> _fetch() async {
    final session = ref.read(authControllerProvider).valueOrNull;
    final result = await ref.read(fetchMyLoadsUseCaseProvider).call(
          MyLoadsInput(
            page: _page,
            limit: _limit,
            isActive: _tab == MyLoadsTab.active,
            userGuid: session?.userGuid,
          ),
        );
    return result.fold((f) => throw f, (list) => list);
  }

  Future<AppFailure?> updateStatus({
    required String guid,
    required bool isActive,
    String? closedPlatform,
  }) async {
    final result = await ref.read(updateLoadStatusUseCaseProvider).call(
          UpdateLoadStatusInput(
            guid: guid,
            isActive: isActive,
            closedPlatform: closedPlatform,
          ),
        );
    return result.fold((f) => f, (_) {
      refresh();
      return null;
    });
  }
}
