import 'package:fpdart/fpdart.dart';
import 'package:loadme_mobile/core/errors/app_failure.dart';

/// Senior-architect explicit error handling.
///
/// Every method that can fail returns `Result<T>` instead of throwing.
/// Callers must explicitly handle both branches:
///
/// ```dart
/// final result = await repo.fetchLoads();
/// result.fold(
///   (failure) => state = AsyncError(failure, st),
///   (loads) => state = AsyncData(loads),
/// );
/// ```
///
/// Built on top of `fpdart`'s `Either<L, R>`:
/// - `Left<AppFailure>`  — error branch
/// - `Right<T>`           — success branch
typedef Result<T> = Either<AppFailure, T>;

/// Async result — same as `Result<T>` but wrapped in a Future.
typedef AsyncResult<T> = Future<Result<T>>;

/// Constructors for ergonomics.
extension ResultX<T> on Result<T> {
  /// Returns the success value or `null` if this is a failure.
  T? get valueOrNull => fold((_) => null, (r) => r);

  /// Returns the failure or `null` if this is a success.
  AppFailure? get failureOrNull => fold((l) => l, (_) => null);

  bool get isSuccess => isRight();
  bool get isFailure => isLeft();
}

/// Helpers to lift values into a `Result`.
Result<T> success<T>(T value) => Right<AppFailure, T>(value);
Result<T> failure<T>(AppFailure f) => Left<AppFailure, T>(f);
