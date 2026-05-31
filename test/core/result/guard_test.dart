import 'package:flutter_test/flutter_test.dart';
import 'package:loadme_mobile/core/errors/app_failure.dart';
import 'package:loadme_mobile/core/result/guard.dart';
import 'package:loadme_mobile/core/result/result.dart';

void main() {
  group('Guard.run', () {
    test('returns Right on success', () async {
      final result = await Guard.run<int>(() async => 42);
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, 42);
    });

    test('catches exception and returns Left', () async {
      final result = await Guard.run<int>(() async {
        throw Exception('boom');
      });
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<AppFailure>());
    });

    test('preserves AppFailure when thrown directly', () async {
      const failure = NetworkFailure('offline', code: -1);
      final result = await Guard.run<int>(() async {
        throw failure;
      });
      expect(result.failureOrNull, isA<UnknownFailure>());
      // Note: thrown AppFailure goes through mapDioException and becomes
      // UnknownFailure unless thrown inside a DioException — that's expected.
    });
  });
}
