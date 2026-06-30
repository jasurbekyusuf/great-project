import 'package:equatable/equatable.dart';
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/core/use_case/use_case.dart';
import 'package:loadme_mobile/features/loads/domain/entities/load_draft.dart';
import 'package:loadme_mobile/features/loads/domain/entities/load_entity.dart';
import 'package:loadme_mobile/features/loads/domain/repositories/loads_repository.dart';

// =============================================================================
// Inputs
// =============================================================================

class PaginatedInput extends Equatable {
  const PaginatedInput({this.page = 1, this.limit = 10, this.filters});
  final int page;
  final int limit;

  /// Server-side location filter (`pickup_region` / `delivery_district` → id).
  /// Null/empty means the unfiltered public feed.
  final Map<String, String>? filters;
  @override
  List<Object?> get props => [page, limit, filters];
}

class MyLoadsInput extends Equatable {
  const MyLoadsInput(
      {this.page = 1, this.limit = 10, required this.isActive, this.userGuid});
  final int page;
  final int limit;
  final bool isActive;
  final String? userGuid;
  @override
  List<Object?> get props => [page, limit, isActive, userGuid];
}

class SaveLoadInput extends Equatable {
  const SaveLoadInput({required this.draft, this.loadId});

  /// Null → create (`POST /loads/`); non-null → edit (`PATCH /loads/{id}/`).
  final String? loadId;
  final LoadDraft draft;
  @override
  List<Object?> get props => [loadId, draft];
}

class UpdateLoadStatusInput extends Equatable {
  const UpdateLoadStatusInput(
      {required this.guid, required this.isActive, this.closedPlatform});
  final String guid;
  final bool isActive;
  final String? closedPlatform;
  @override
  List<Object?> get props => [guid, isActive, closedPlatform];
}

// =============================================================================
// Use cases
// =============================================================================

class FetchLoadsUseCase implements UseCase<PaginatedInput, List<LoadEntity>> {
  const FetchLoadsUseCase(this._repo);
  final LoadsRepository _repo;
  @override
  AsyncResult<List<LoadEntity>> call(PaginatedInput input) => _repo.getLoads(
        page: input.page,
        limit: input.limit,
        filters: input.filters,
      );
}

class FetchMyLoadsUseCase implements UseCase<MyLoadsInput, List<LoadEntity>> {
  const FetchMyLoadsUseCase(this._repo);
  final LoadsRepository _repo;
  @override
  AsyncResult<List<LoadEntity>> call(MyLoadsInput input) => _repo.getMyLoads(
        page: input.page,
        limit: input.limit,
        isActive: input.isActive,
        userGuid: input.userGuid,
      );
}

class FetchLoadByIdUseCase implements UseCase<String, LoadEntity> {
  const FetchLoadByIdUseCase(this._repo);
  final LoadsRepository _repo;
  @override
  AsyncResult<LoadEntity> call(String id) => _repo.getLoadById(id);
}

class SaveLoadUseCase implements UseCase<SaveLoadInput, void> {
  const SaveLoadUseCase(this._repo);
  final LoadsRepository _repo;
  @override
  AsyncResult<void> call(SaveLoadInput input) {
    if (input.loadId == null) return _repo.addLoad(input.draft);
    return _repo.updateLoad(input.loadId!, input.draft);
  }
}

class UpdateLoadStatusUseCase implements UseCase<UpdateLoadStatusInput, void> {
  const UpdateLoadStatusUseCase(this._repo);
  final LoadsRepository _repo;
  @override
  AsyncResult<void> call(UpdateLoadStatusInput input) => _repo.updateLoadStatus(
        guid: input.guid,
        isActive: input.isActive,
        closedPlatform: input.closedPlatform,
      );
}
