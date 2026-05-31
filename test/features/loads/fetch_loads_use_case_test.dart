import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:loadme_mobile/core/errors/app_failure.dart';
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/features/loads/domain/entities/load_entity.dart';
import 'package:loadme_mobile/features/loads/domain/repositories/loads_repository.dart';
import 'package:loadme_mobile/features/loads/domain/use_cases/loads_use_cases.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements LoadsRepository {}

void main() {
  late _MockRepo repo;
  late FetchLoadsUseCase useCase;

  setUp(() {
    repo = _MockRepo();
    useCase = FetchLoadsUseCase(repo);
  });

  test('forwards page/limit and returns loads on success', () async {
    const expected = [
      LoadEntity(guid: '1', fromAddress: 'A', toAddress: 'B'),
    ];
    when(() => repo.getLoads(page: any(named: 'page'), limit: any(named: 'limit')))
        .thenAnswer((_) async => const Right(expected));

    final result = await useCase.call(const PaginatedInput(page: 2, limit: 5));

    expect(result.valueOrNull, expected);
    verify(() => repo.getLoads(page: 2, limit: 5)).called(1);
  });

  test('returns failure unchanged', () async {
    when(() => repo.getLoads(page: any(named: 'page'), limit: any(named: 'limit')))
        .thenAnswer((_) async => const Left(NetworkFailure('offline')));

    final result = await useCase.call(const PaginatedInput());

    expect(result.failureOrNull, isA<NetworkFailure>());
  });
}
