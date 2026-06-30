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
/// header on the marketplace. Keyed by a canonical [trucksFilterKey]: the empty
/// key returns the whole-feed total, a `pickup_*`/`delivery_*` key returns the
/// filtered total after a Qidiruv ("Topildi: N"). Separate from the paginated
/// list so the count reflects the real backend total.
final trucksCountProvider =
    FutureProvider.autoDispose.family<int, String>((ref, filterKey) async {
  final result = await ref
      .watch(trucksRepositoryProvider)
      .getTrucksCount(filters: trucksFilterMap(filterKey));
  return result.fold((f) => throw f, (count) => count);
});

/// Order-independent string key for a trucks filter map, so the autoDispose
/// `.family` count provider stays stable (a raw `Map` has no value equality).
String trucksFilterKey(Map<String, String> filters) {
  if (filters.isEmpty) return '';
  final keys = filters.keys.toList()..sort();
  return [for (final k in keys) '$k=${filters[k]}'].join('&');
}

/// Inverse of [trucksFilterKey] — rebuilds the filter map a `.family` provider
/// was keyed with so it can re-issue the same server filter.
Map<String, String> trucksFilterMap(String key) {
  if (key.isEmpty) return const {};
  final out = <String, String>{};
  for (final part in key.split('&')) {
    final i = part.indexOf('=');
    if (i > 0) out[part.substring(0, i)] = part.substring(i + 1);
  }
  return out;
}

/// The trucks location filter currently applied to the public feed (`pickup_*` /
/// `delivery_*` → place id, plus `truck_type`). Single source of truth shared by
/// [TrucksController] (which pages the narrowed feed) and the marketplace count
/// header (which keys [trucksCountProvider] off it), so the header total always
/// matches the rows the list shows. Mirrors `activeLoadsFilterProvider`.
final activeTrucksFilterProvider =
    StateProvider<Map<String, String>>((ref) => const {});

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
    // Watch the active filter so a new Qidiruv / Filtrlar selection re-runs
    // build (fresh page 1) and stays in lock-step with the count header.
    final filters = ref.watch(activeTrucksFilterProvider);
    final result = await ref
        .read(fetchTrucksUseCaseProvider)
        .call(PaginatedInput(page: 1, limit: _limit, filters: filters));
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
    final filters = ref.read(activeTrucksFilterProvider);
    final result = await ref
        .read(fetchTrucksUseCaseProvider)
        .call(PaginatedInput(page: 1, limit: _limit, filters: filters));
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
    final filters = ref.read(activeTrucksFilterProvider);
    final result = await ref
        .read(fetchTrucksUseCaseProvider)
        .call(PaginatedInput(page: next, limit: _limit, filters: filters));
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

  /// Applies the Qidiruv / Filtrlar "Qayerdan / Qayerga" choice as a *server*
  /// filter on `/trucks/routes/available/`. Writing [activeTrucksFilterProvider]
  /// re-runs [build] (fresh page 1) — so the whole feed narrows, not just the
  /// rows already paged in — and updates the count header in the same tick. An
  /// empty map clears the filter. Mirrors `LoadsController.applyLocationFilter`.
  void applyLocationFilter(Map<String, String> filters) {
    ref.read(activeTrucksFilterProvider.notifier).state =
        Map<String, String>.unmodifiable(filters);
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
