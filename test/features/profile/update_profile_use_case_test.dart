import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:loadme_mobile/core/errors/app_failure.dart';
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/features/profile/domain/entities/profile_entity.dart';
import 'package:loadme_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:loadme_mobile/features/profile/domain/use_cases/update_profile_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ProfileRepository {}

void main() {
  late _MockRepo repo;
  late UpdateProfileUseCase useCase;

  setUp(() {
    repo = _MockRepo();
    useCase = UpdateProfileUseCase(repo);
  });

  test('forwards every input field to the repository and returns the result',
      () async {
    const updated = ProfileEntity(guid: 'g', fullName: 'New Name');
    when(
      () => repo.updateProfile(
        fullName: any(named: 'fullName'),
        companyName: any(named: 'companyName'),
        personType: any(named: 'personType'),
        telegramUsername: any(named: 'telegramUsername'),
        whatsappNumber: any(named: 'whatsappNumber'),
      ),
    ).thenAnswer((_) async => const Right(updated));

    final result = await useCase.call(
      const UpdateProfileInput(
        fullName: 'New Name',
        personType: 'legal',
        telegramUsername: 'niko',
        whatsappNumber: '+998901234567',
      ),
    );

    expect(result.valueOrNull, updated);
    verify(
      () => repo.updateProfile(
        fullName: 'New Name',
        companyName: null,
        personType: 'legal',
        telegramUsername: 'niko',
        whatsappNumber: '+998901234567',
      ),
    ).called(1);
  });

  test('returns failure unchanged', () async {
    when(
      () => repo.updateProfile(
        fullName: any(named: 'fullName'),
        companyName: any(named: 'companyName'),
        personType: any(named: 'personType'),
        telegramUsername: any(named: 'telegramUsername'),
        whatsappNumber: any(named: 'whatsappNumber'),
      ),
    ).thenAnswer((_) async => const Left(UnknownFailure('boom')));

    final result = await useCase.call(const UpdateProfileInput(fullName: 'x'));

    expect(result.failureOrNull, isA<UnknownFailure>());
  });
}
