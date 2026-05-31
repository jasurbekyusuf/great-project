import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:loadme_mobile/core/errors/app_failure.dart';
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/features/loads/domain/repositories/loads_repository.dart';
import 'package:loadme_mobile/features/loads/domain/use_cases/loads_use_cases.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements LoadsRepository {}

void main() {
  late _MockRepo repo;
  late UpdateLoadStatusUseCase useCase;

  setUp(() {
    repo = _MockRepo();
    useCase = UpdateLoadStatusUseCase(repo);
  });

  test('forwards all fields to repository', () async {
    when(() => repo.updateLoadStatus(
          guid: any(named: 'guid'),
          isActive: any(named: 'isActive'),
          closedPlatform: any(named: 'closedPlatform'),
        )).thenAnswer((_) async => const Right(null));

    final result = await useCase.call(const UpdateLoadStatusInput(
      guid: 'load-7',
      isActive: false,
      closedPlatform: 'loadme',
    ));

    expect(result.isSuccess, isTrue);
    verify(() => repo.updateLoadStatus(
          guid: 'load-7',
          isActive: false,
          closedPlatform: 'loadme',
        )).called(1);
  });

  test('returns NotFoundFailure when load is missing', () async {
    when(() => repo.updateLoadStatus(
          guid: any(named: 'guid'),
          isActive: any(named: 'isActive'),
          closedPlatform: any(named: 'closedPlatform'),
        )).thenAnswer((_) async => const Left(NotFoundFailure()));

    final result = await useCase.call(
      const UpdateLoadStatusInput(guid: 'missing', isActive: true),
    );

    expect(result.failureOrNull, isA<NotFoundFailure>());
  });
}
