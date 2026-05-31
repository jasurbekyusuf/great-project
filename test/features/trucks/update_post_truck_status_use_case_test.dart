import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:loadme_mobile/core/errors/app_failure.dart';
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/features/trucks/domain/repositories/trucks_repository.dart';
import 'package:loadme_mobile/features/trucks/domain/use_cases/trucks_use_cases.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements TrucksRepository {}

void main() {
  late _MockRepo repo;
  late UpdatePostTruckStatusUseCase useCase;

  setUp(() {
    repo = _MockRepo();
    useCase = UpdatePostTruckStatusUseCase(repo);
  });

  test('archives a posted truck', () async {
    when(() => repo.updatePostTruckStatus(
          guid: any(named: 'guid'),
          isActive: any(named: 'isActive'),
        )).thenAnswer((_) async => const Right(null));

    final result = await useCase.call(
      const UpdateTruckStatusInput(guid: 'pt-1', isActive: false),
    );

    expect(result.isSuccess, isTrue);
    verify(() => repo.updatePostTruckStatus(guid: 'pt-1', isActive: false))
        .called(1);
  });

  test('propagates unauthorized', () async {
    when(() => repo.updatePostTruckStatus(
          guid: any(named: 'guid'),
          isActive: any(named: 'isActive'),
        )).thenAnswer((_) async => const Left(UnauthorizedFailure()));

    final result = await useCase.call(
      const UpdateTruckStatusInput(guid: 'pt-1', isActive: false),
    );

    expect(result.failureOrNull, isA<UnauthorizedFailure>());
  });
}
