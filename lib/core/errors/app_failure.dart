import 'package:equatable/equatable.dart';

/// Sealed hierarchy of all app-level failures.
///
/// Every layer (data → domain → presentation) speaks this language instead
/// of throwing arbitrary exceptions. Maps from Dio/socket errors at the
/// repository boundary.
///
/// Implements [Exception] so it satisfies `only_throw_errors` when it's
/// rethrown into Riverpod's `AsyncError`.
sealed class AppFailure extends Equatable implements Exception {
  const AppFailure(this.message, {this.code, this.cause});

  final String message;
  final int? code;
  final Object? cause;

  @override
  List<Object?> get props => [runtimeType, message, code];

  @override
  String toString() => '$runtimeType($code): $message';
}

class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message, {super.code, super.cause});
}

class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([super.message = 'Unauthorized', int? code])
      : super(code: code);
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'Not found', int? code])
      : super(code: code);
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, {this.fieldErrors = const {}, super.code});
  final Map<String, String> fieldErrors;
}

class CacheFailure extends AppFailure {
  const CacheFailure(super.message, {super.cause});
}

class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message = 'Unknown error', Object? cause])
      : super(cause: cause);
}
