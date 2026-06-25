import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/errors/app_failure.dart';
import 'package:loadme_mobile/core/network/dio_client.dart';
import 'package:loadme_mobile/features/trucks/data/datasources/trucks_remote_data_source.dart';
import 'package:loadme_mobile/features/trucks/data/repositories/trucks_repository_impl.dart';
import 'package:loadme_mobile/features/trucks/domain/entities/truck_detail_entity.dart';
import 'package:loadme_mobile/features/trucks/domain/entities/truck_entity.dart';
import 'package:loadme_mobile/features/trucks/domain/repositories/trucks_repository.dart';
import 'package:loadme_mobile/features/trucks/domain/use_cases/trucks_use_cases.dart';

// -----------------------------------------------------------------------------
// DI wiring
// -----------------------------------------------------------------------------

final trucksRepositoryProvider = Provider<TrucksRepository>(
  (ref) => TrucksRepositoryImpl(TrucksRemoteDataSource(ref.watch(dioProvider))),
);

final fetchTrucksUseCaseProvider =
    Provider((ref) => FetchTrucksUseCase(ref.watch(trucksRepositoryProvider)));
final fetchMyPostTrucksUseCaseProvider =
    Provider((ref) => FetchMyPostTrucksUseCase(ref.watch(trucksRepositoryProvider)));
final fetchMyTrucksUseCaseProvider =
    Provider((ref) => FetchMyTrucksUseCase(ref.watch(trucksRepositoryProvider)));
final fetchTruckByIdUseCaseProvider =
    Provider((ref) => FetchTruckByIdUseCase(ref.watch(trucksRepositoryProvider)));
final updatePostTruckStatusUseCaseProvider =
    Provider((ref) => UpdatePostTruckStatusUseCase(ref.watch(trucksRepositoryProvider)));
final updateTruckStatusUseCaseProvider =
    Provider((ref) => UpdateTruckStatusUseCase(ref.watch(trucksRepositoryProvider)));

final truckDetailsProvider =
    FutureProvider.family.autoDispose<TruckDetailEntity, String>((ref, id) async {
  final result = await ref.read(fetchTruckByIdUseCaseProvider).call(id);
  return result.fold((f) => throw f, (e) => e);
});

/// Total number of public truck routes — drives the "Bo'sh transportlar: N"
/// header on the marketplace. Separate from the paginated list so the count
/// reflects the real backend total.
final trucksCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final result = await ref.watch(trucksRepositoryProvider).getTrucksCount();
  return result.fold((f) => throw f, (count) => count);
});

// -----------------------------------------------------------------------------
// Controllers
// -----------------------------------------------------------------------------

final trucksControllerProvider =
    AutoDisposeAsyncNotifierProvider<TrucksController, List<TruckEntity>>(
        TrucksController.new);
final myTrucksControllerProvider =
    AutoDisposeAsyncNotifierProvider<MyTrucksController, List<TruckEntity>>(
        MyTrucksController.new);

enum MyTrucksTab { available, myTrucks, history }

class TrucksController extends AutoDisposeAsyncNotifier<List<TruckEntity>> {
  static const _limit = 10;
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  // Raw items accumulated across pages. Each `state = AsyncData(...)` hands back
  // a *fresh* copy so Riverpod doesn't swallow the rebuild on list identity.
  final List<TruckEntity> _all = [];

  /// Another page may still be fetched (the last page came back full).
  bool get hasMore => _hasMore;

  /// A [loadMore] fetch is currently in flight.
  bool get isLoadingMore => _loadingMore;

  @override
  Future<List<TruckEntity>> build() async {
    _page = 1;
    _hasMore = true;
    _loadingMore = false;
    final result = await ref
        .read(fetchTrucksUseCaseProvider)
        .call(const PaginatedInput(page: 1, limit: _limit));
    return result.fold(
      (f) => throw f,
      (list) {
        _all
          ..clear()
          ..addAll(list);
        _hasMore = list.length >= _limit;
        return List<TruckEntity>.from(_all);
      },
    );
  }

  Future<void> refresh() async {
    _page = 1;
    _hasMore = true;
    _loadingMore = false;
    state = const AsyncLoading();
    final result = await ref
        .read(fetchTrucksUseCaseProvider)
        .call(const PaginatedInput(page: 1, limit: _limit));
    state = result.fold(
      (f) => AsyncError(f, StackTrace.current),
      (list) {
        _all
          ..clear()
          ..addAll(list);
        _hasMore = list.length >= _limit;
        return AsyncData(List<TruckEntity>.from(_all));
      },
    );
  }

  /// Fetch the next page and append it. No-op while a page is in flight, once
  /// the backend returns a short (final) page, or before the first page lands.
  /// A failed page is swallowed so the next scroll can retry.
  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore || state.valueOrNull == null) return;
    _loadingMore = true;
    final next = _page + 1;
    final result = await ref
        .read(fetchTrucksUseCaseProvider)
        .call(PaginatedInput(page: next, limit: _limit));
    _loadingMore = false;
    result.fold(
      (_) {},
      (list) {
        _page = next;
        _hasMore = list.length >= _limit;
        _all.addAll(list);
        state = AsyncData(List<TruckEntity>.from(_all));
      },
    );
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
    final list = await _fetch();
    state = AsyncData(list);
  }

  Future<List<TruckEntity>> _fetch() async {
    final result = await switch (_tab) {
      MyTrucksTab.available => ref
          .read(fetchMyPostTrucksUseCaseProvider)
          .call(MyPostTrucksInput(page: _page, limit: _limit, isActive: true)),
      MyTrucksTab.myTrucks => ref
          .read(fetchMyTrucksUseCaseProvider)
          .call(PaginatedInput(page: _page, limit: _limit)),
      MyTrucksTab.history => ref
          .read(fetchMyPostTrucksUseCaseProvider)
          .call(MyPostTrucksInput(page: _page, limit: _limit, isActive: false)),
    };
    return result.fold((f) => throw f, (list) => list);
  }

  Future<AppFailure?> updateCurrentItemStatus({
    required String guid,
    required bool isActive,
  }) async {
    final useCase = _tab == MyTrucksTab.myTrucks
        ? ref.read(updateTruckStatusUseCaseProvider)
        : ref.read(updatePostTruckStatusUseCaseProvider);
    final result = await useCase.call(UpdateTruckStatusInput(guid: guid, isActive: isActive));
    return result.fold((f) => f, (_) {
      refresh();
      return null;
    });
  }

  Future<AppFailure?> updateTruckStatus({required String guid, required bool isActive}) async {
    final result = await ref
        .read(updateTruckStatusUseCaseProvider)
        .call(UpdateTruckStatusInput(guid: guid, isActive: isActive));
    return result.fold((f) => f, (_) {
      refresh();
      return null;
    });
  }

  Future<AppFailure?> updatePostTruckStatus({required String guid, required bool isActive}) async {
    final result = await ref
        .read(updatePostTruckStatusUseCaseProvider)
        .call(UpdateTruckStatusInput(guid: guid, isActive: isActive));
    return result.fold((f) => f, (_) {
      refresh();
      return null;
    });
  }
}
