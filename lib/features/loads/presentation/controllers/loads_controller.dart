import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/errors/app_failure.dart';
import 'package:loadme_mobile/core/network/dio_client.dart';
import 'package:loadme_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:loadme_mobile/features/loads/data/datasources/loads_remote_data_source.dart';
import 'package:loadme_mobile/features/loads/data/repositories/loads_repository_impl.dart';
import 'package:loadme_mobile/features/loads/domain/entities/load_entity.dart';
import 'package:loadme_mobile/features/loads/domain/repositories/loads_repository.dart';
import 'package:loadme_mobile/features/loads/domain/use_cases/loads_use_cases.dart';

// -----------------------------------------------------------------------------
// DI wiring
// -----------------------------------------------------------------------------

final loadsRepositoryProvider = Provider<LoadsRepository>(
  (ref) => LoadsRepositoryImpl(LoadsRemoteDataSource(ref.watch(dioProvider))),
);

final fetchLoadsUseCaseProvider =
    Provider((ref) => FetchLoadsUseCase(ref.watch(loadsRepositoryProvider)));
final fetchMyLoadsUseCaseProvider =
    Provider((ref) => FetchMyLoadsUseCase(ref.watch(loadsRepositoryProvider)));
final fetchLoadByIdUseCaseProvider =
    Provider((ref) => FetchLoadByIdUseCase(ref.watch(loadsRepositoryProvider)));
final saveLoadUseCaseProvider =
    Provider((ref) => SaveLoadUseCase(ref.watch(loadsRepositoryProvider)));
final updateLoadStatusUseCaseProvider = Provider(
    (ref) => UpdateLoadStatusUseCase(ref.watch(loadsRepositoryProvider)));

/// Total number of public loads — drives the marketplace count header. Keyed by
/// a canonical [loadsFilterKey]: the empty key returns the whole-feed total
/// ("Barcha yuklar: N"), a `pickup_*`/`delivery_*` key returns the filtered
/// total after a Qidiruv ("Topildi: N"). Kept separate from the (paginated)
/// list so the count is the real backend total, not just the rows loaded.
final loadsCountProvider =
    FutureProvider.autoDispose.family<int, String>((ref, filterKey) async {
  final result = await ref
      .watch(loadsRepositoryProvider)
      .getLoadsCount(filters: loadsFilterMap(filterKey));
  return result.fold((f) => throw f, (count) => count);
});

/// Order-independent string key for a loads filter map, so the autoDispose
/// `.family` count / nearby providers stay stable (a raw `Map` has no value
/// equality — two equal maps would otherwise spawn distinct providers).
String loadsFilterKey(Map<String, String> filters) {
  if (filters.isEmpty) return '';
  final keys = filters.keys.toList()..sort();
  return [for (final k in keys) '$k=${filters[k]}'].join('&');
}

/// Inverse of [loadsFilterKey] — rebuilds the `pickup_*`/`delivery_*` map a
/// `.family` provider was keyed with so it can re-issue the same server filter.
Map<String, String> loadsFilterMap(String key) {
  if (key.isEmpty) return const {};
  final out = <String, String>{};
  for (final part in key.split('&')) {
    final i = part.indexOf('=');
    if (i > 0) out[part.substring(0, i)] = part.substring(i + 1);
  }
  return out;
}

/// The loads location filter currently applied to the public feed (`pickup_*` /
/// `delivery_*` → place id). Single source of truth shared by [LoadsController]
/// (which pages the narrowed feed) and the marketplace count header (which keys
/// [loadsCountProvider] off it), so "Topildi: N" always matches the rows the
/// list actually shows — whether the filter came from the Qidiruv search sheet
/// or the Filtrlar screen.
final activeLoadsFilterProvider =
    StateProvider<Map<String, String>>((ref) => const {});

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
  static const _limit = 10;
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  String? _query;

  // Raw items accumulated across pages. `state` always exposes the *filtered*
  // view of this list, so server pagination and the client-side search filter
  // stay coherent: a new page is appended here, then the whole thing re-filtered.
  final List<LoadEntity> _all = [];

  /// Another page may still be fetched (the last page came back full).
  bool get hasMore => _hasMore;

  /// A [loadMore] fetch is currently in flight.
  bool get isLoadingMore => _loadingMore;

  @override
  Future<List<LoadEntity>> build() async {
    _page = 1;
    _hasMore = true;
    _loadingMore = false;
    // Watch the active filter so a new Qidiruv / Filtrlar selection re-runs
    // build (fresh page 1) and stays in lock-step with the count header, which
    // keys [loadsCountProvider] off the very same provider.
    final locationFilters = ref.watch(activeLoadsFilterProvider);
    final result = await ref.read(fetchLoadsUseCaseProvider).call(
        PaginatedInput(page: 1, limit: _limit, filters: locationFilters));
    return result.fold(
      (f) => throw f,
      (list) {
        _all
          ..clear()
          ..addAll(list);
        _hasMore = list.length >= _limit;
        return _applyFilter(_all);
      },
    );
  }

  Future<void> refresh() async {
    _page = 1;
    _hasMore = true;
    _loadingMore = false;
    state = const AsyncLoading();
    final locationFilters = ref.read(activeLoadsFilterProvider);
    final result = await ref.read(fetchLoadsUseCaseProvider).call(
        PaginatedInput(page: 1, limit: _limit, filters: locationFilters));
    state = result.fold(
      (f) => AsyncError(f, StackTrace.current),
      (list) {
        _all
          ..clear()
          ..addAll(list);
        _hasMore = list.length >= _limit;
        return AsyncData(_applyFilter(_all));
      },
    );
  }

  /// Fetch the next page and append it to the list already on screen. No-op
  /// while a page is in flight, once the backend returns a short (final) page,
  /// or before the first page has arrived. A failed page is swallowed so the
  /// next scroll can retry without tearing down the visible list.
  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore || state.valueOrNull == null) return;
    _loadingMore = true;
    final next = _page + 1;
    final locationFilters = ref.read(activeLoadsFilterProvider);
    final result =
        await ref.read(fetchLoadsUseCaseProvider).call(PaginatedInput(
              page: next,
              limit: _limit,
              filters: locationFilters,
            ));
    _loadingMore = false;
    result.fold(
      (_) {},
      (list) {
        _page = next;
        _hasMore = list.length >= _limit;
        _all.addAll(list);
        state = AsyncData(_applyFilter(_all));
      },
    );
  }

  void applyQuery(String query) {
    _query = query.trim().isEmpty ? null : query.trim().toLowerCase();
    state = AsyncData(_applyFilter(_all));
  }

  /// Applies the Qidiruv / Filtrlar "Qayerdan / Qayerga" choice as a *server*
  /// filter on `/loads/available/`. Writing [activeLoadsFilterProvider] re-runs
  /// [build] (fresh page 1) — so the whole marketplace narrows, not just the
  /// rows already paged in — and updates the count header in the same tick,
  /// since it keys off the very same provider. An empty map clears the filter.
  void applyLocationFilter(Map<String, String> filters) {
    ref.read(activeLoadsFilterProvider.notifier).state =
        Map<String, String>.unmodifiable(filters);
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

  // Always returns a *fresh* list so each `state = AsyncData(...)` is a distinct
  // instance and Riverpod notifies listeners — handing back the same `_all`
  // reference twice would compare equal and the rebuild would be swallowed.
  List<LoadEntity> _applyFilter(List<LoadEntity> input) {
    final base = _query == null
        ? input
        : input.where((e) =>
            e.fromAddress.toLowerCase().contains(_query!) ||
            e.toAddress.toLowerCase().contains(_query!));
    return List<LoadEntity>.from(base);
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
