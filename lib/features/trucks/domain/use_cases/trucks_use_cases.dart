import 'package:equatable/equatable.dart';
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/core/use_case/use_case.dart';
import 'package:loadme_mobile/features/trucks/domain/entities/truck_detail_entity.dart';
import 'package:loadme_mobile/features/trucks/domain/entities/truck_entity.dart';
import 'package:loadme_mobile/features/trucks/domain/repositories/trucks_repository.dart';

class PaginatedInput extends Equatable {
  const PaginatedInput({this.page = 1, this.limit = 10});
  final int page;
  final int limit;
  @override
  List<Object?> get props => [page, limit];
}

class MyPostTrucksInput extends Equatable {
  const MyPostTrucksInput({this.page = 1, this.limit = 10, required this.isActive});
  final int page;
  final int limit;
  final bool isActive;
  @override
  List<Object?> get props => [page, limit, isActive];
}

class UpdateTruckStatusInput extends Equatable {
  const UpdateTruckStatusInput({required this.guid, required this.isActive});
  final String guid;
  final bool isActive;
  @override
  List<Object?> get props => [guid, isActive];
}

class FetchTrucksUseCase implements UseCase<PaginatedInput, List<TruckEntity>> {
  const FetchTrucksUseCase(this._repo);
  final TrucksRepository _repo;
  @override
  AsyncResult<List<TruckEntity>> call(PaginatedInput input) =>
      _repo.getTrucks(page: input.page, limit: input.limit);
}

class FetchMyPostTrucksUseCase implements UseCase<MyPostTrucksInput, List<TruckEntity>> {
  const FetchMyPostTrucksUseCase(this._repo);
  final TrucksRepository _repo;
  @override
  AsyncResult<List<TruckEntity>> call(MyPostTrucksInput input) =>
      _repo.getMyPostTrucks(page: input.page, limit: input.limit, isActive: input.isActive);
}

class FetchMyTrucksUseCase implements UseCase<PaginatedInput, List<TruckEntity>> {
  const FetchMyTrucksUseCase(this._repo);
  final TrucksRepository _repo;
  @override
  AsyncResult<List<TruckEntity>> call(PaginatedInput input) =>
      _repo.getMyTrucks(page: input.page, limit: input.limit);
}

class FetchTruckByIdUseCase implements UseCase<String, TruckDetailEntity> {
  const FetchTruckByIdUseCase(this._repo);
  final TrucksRepository _repo;
  @override
  AsyncResult<TruckDetailEntity> call(String id) => _repo.getTruckById(id);
}

class UpdatePostTruckStatusUseCase implements UseCase<UpdateTruckStatusInput, void> {
  const UpdatePostTruckStatusUseCase(this._repo);
  final TrucksRepository _repo;
  @override
  AsyncResult<void> call(UpdateTruckStatusInput input) =>
      _repo.updatePostTruckStatus(guid: input.guid, isActive: input.isActive);
}

class UpdateTruckStatusUseCase implements UseCase<UpdateTruckStatusInput, void> {
  const UpdateTruckStatusUseCase(this._repo);
  final TrucksRepository _repo;
  @override
  AsyncResult<void> call(UpdateTruckStatusInput input) =>
      _repo.updateTruckStatus(guid: input.guid, isActive: input.isActive);
}
