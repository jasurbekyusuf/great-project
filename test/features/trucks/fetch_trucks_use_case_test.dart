import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:loadme_mobile/core/errors/app_failure.dart';
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/features/trucks/domain/entities/truck_entity.dart';
import 'package:loadme_mobile/features/trucks/domain/repositories/trucks_repository.dart';
import 'package:loadme_mobile/features/trucks/domain/use_cases/trucks_use_cases.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements TrucksRepository {}

void main() {
  late _MockRepo repo;
  late FetchTrucksUseCase useCase;

  setUp(() {
    repo = _MockRepo();
    useCase = FetchTrucksUseCase(repo);
  });

  test('returns trucks on success', () async {
    const expected = [TruckEntity(guid: 't1', fromAddress: 'A', toAddress: 'B')];
    when(() => repo.getTrucks(page: any(named: 'page'), limit: any(named: 'limit')))
        .thenAnswer((_) async => const Right(expected));

    final result = await useCase.call(const PaginatedInput());

    expect(result.valueOrNull, expected);
  });

  test('returns failure on repository error', () async {
    when(() => repo.getTrucks(page: any(named: 'page'), limit: any(named: 'limit')))
        .thenAnswer((_) async => const Left(UnauthorizedFailure()));

    final result = await useCase.call(const PaginatedInput());

    expect(result.failureOrNull, isA<UnauthorizedFailure>());
  });
}
