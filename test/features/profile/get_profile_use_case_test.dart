import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:loadme_mobile/core/errors/app_failure.dart';
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/features/profile/domain/entities/profile_entity.dart';
import 'package:loadme_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:loadme_mobile/features/profile/domain/use_cases/get_profile_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ProfileRepository {}

void main() {
  late _MockRepo repo;
  late GetProfileUseCase useCase;

  setUp(() {
    repo = _MockRepo();
    useCase = GetProfileUseCase(repo);
  });

  test('returns profile on success', () async {
    const expected = ProfileEntity(guid: 'g', fullName: 'Test User');
    when(repo.getProfile).thenAnswer((_) async => const Right(expected));

    final result = await useCase.call();

    expect(result.valueOrNull, expected);
  });

  test('returns failure unchanged', () async {
    when(repo.getProfile)
        .thenAnswer((_) async => const Left(UnknownFailure('boom')));

    final result = await useCase.call();

    expect(result.failureOrNull, isA<UnknownFailure>());
  });
}
