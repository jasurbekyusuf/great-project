import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/errors/app_failure.dart';
import 'package:loadme_mobile/core/network/dio_client.dart';
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/features/loads/data/datasources/loads_remote_data_source.dart';
import 'package:loadme_mobile/features/saved/data/datasources/saved_remote_data_source.dart';
import 'package:loadme_mobile/features/saved/data/repositories/saved_repository_impl.dart';
import 'package:loadme_mobile/features/saved/domain/entities/saved_load.dart';
import 'package:loadme_mobile/features/saved/domain/repositories/saved_repository.dart';

// Re-export the entity so screens need only one import.
export 'package:loadme_mobile/features/saved/domain/entities/saved_load.dart';

/// Favorites repository over the shared [dioProvider] (bearer auto-attached).
/// Reuses [LoadsRemoteDataSource] purely for its enriched load parsing.
final savedRepositoryProvider = Provider<SavedRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SavedRepositoryImpl(
    SavedRemoteDataSource(dio, LoadsRemoteDataSource(dio)),
  );
});

/// The "Saqlanganlar" list + save/un-save mutations.
final savedControllerProvider =
    AutoDisposeAsyncNotifierProvider<SavedController, List<SavedLoad>>(
  SavedController.new,
);

class SavedController extends AutoDisposeAsyncNotifier<List<SavedLoad>> {
  SavedRepository get _repo => ref.read(savedRepositoryProvider);

  @override
  Future<List<SavedLoad>> build() async {
    final result = await _repo.getSaved();
    return result.fold((f) => throw f, (list) => list);
  }

  /// Re-fetch from REST (pull-to-refresh and error-retry).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.getSaved();
      return result.fold((f) => throw f, (list) => list);
    });
  }

  /// Whether [loadId] is currently saved (matched by favorite id or load guid).
  bool isSaved(String loadId) {
    final current = state.valueOrNull ?? const <SavedLoad>[];
    return current.any((s) => s.id == loadId || s.load.guid == loadId);
  }

  /// Saves [loadId], then silently reconciles the list (no loading flash so the
  /// bookmark doesn't flicker). Returns the failure on error, else null.
  Future<AppFailure?> add(String loadId) async {
    final result = await _repo.addSaved(loadId);
    final failure = result.failureOrNull;
    if (failure != null) return failure;
    await _reloadSilently();
    return null;
  }

  /// Optimistically removes the entry backing [loadId], then persists. A failed
  /// DELETE re-syncs from the server. Returns the failure on error, else null.
  Future<AppFailure?> removeByLoad(String loadId) async {
    final current = state.valueOrNull ?? const <SavedLoad>[];
    final stillThere =
        current.any((s) => s.id == loadId || s.load.guid == loadId);
    if (!stillThere) return null;
    // Favorites are keyed by load id; drop optimistically, then persist.
    state = AsyncData(
      current.where((s) => s.id != loadId && s.load.guid != loadId).toList(),
    );
    final result = await _repo.removeSaved(loadId);
    final failure = result.failureOrNull;
    if (failure != null) {
      await _reloadSilently();
      return failure;
    }
    return null;
  }

  /// Re-fetches and swaps in the fresh list without an [AsyncLoading] flash;
  /// a failed reload leaves the current optimistic state untouched.
  Future<void> _reloadSilently() async {
    final result = await _repo.getSaved();
    result.fold((_) {}, (list) => state = AsyncData(list));
  }
}

/// Saved transport routes (the bookmark on the Transport detail). Holds the set
/// of saved route ids so the header icon can render its active state; add /
/// un-save hit `POST|DELETE /favorites/routes/{id}/`.
final savedRoutesControllerProvider =
    AutoDisposeAsyncNotifierProvider<SavedRoutesController, Set<String>>(
  SavedRoutesController.new,
);

class SavedRoutesController extends AutoDisposeAsyncNotifier<Set<String>> {
  SavedRepository get _repo => ref.read(savedRepositoryProvider);

  @override
  Future<Set<String>> build() async {
    final result = await _repo.getSavedRouteIds();
    return result.fold((f) => throw f, (ids) => ids);
  }

  /// Whether [routeId] is currently saved.
  bool isSaved(String routeId) =>
      state.valueOrNull?.contains(routeId) ?? false;

  /// Saves [routeId] optimistically; reverts and returns the failure on error.
  Future<AppFailure?> add(String routeId) async {
    final current = state.valueOrNull ?? const <String>{};
    if (current.contains(routeId)) return null;
    state = AsyncData({...current, routeId});
    final failure = (await _repo.addSavedRoute(routeId)).failureOrNull;
    if (failure != null) {
      state = AsyncData(current);
      return failure;
    }
    return null;
  }

  /// Un-saves [routeId] optimistically; reverts and returns the failure on
  /// error.
  Future<AppFailure?> removeById(String routeId) async {
    final current = state.valueOrNull ?? const <String>{};
    if (!current.contains(routeId)) return null;
    state = AsyncData({...current}..remove(routeId));
    final failure = (await _repo.removeSavedRoute(routeId)).failureOrNull;
    if (failure != null) {
      state = AsyncData(current);
      return failure;
    }
    return null;
  }
}
