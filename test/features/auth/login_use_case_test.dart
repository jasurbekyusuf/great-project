import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:loadme_mobile/core/errors/app_failure.dart';
import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:loadme_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:loadme_mobile/features/auth/domain/use_cases/login_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AuthRepository {}

void main() {
  late _MockRepo repo;
  late LoginUseCase useCase;

  setUp(() {
    repo = _MockRepo();
    useCase = LoginUseCase(repo);
  });

  group('LoginUseCase', () {
    test('returns session on success', () async {
      const expected = AuthSession(token: 't', fullName: 'Test User');
      when(() => repo.login(phone: any(named: 'phone'), password: any(named: 'password')))
          .thenAnswer((_) async => const Right(expected));

      final result =
          await useCase.call(const LoginInput(phone: '+998900000000', password: 'pw'));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, expected);
      verify(() => repo.login(phone: '+998900000000', password: 'pw')).called(1);
    });

    test('propagates failure unchanged', () async {
      const failure = NetworkFailure('No internet');
      when(() => repo.login(phone: any(named: 'phone'), password: any(named: 'password')))
          .thenAnswer((_) async => const Left(failure));

      final result =
          await useCase.call(const LoginInput(phone: '+998900000000', password: 'pw'));

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, failure);
    });
  });
}
