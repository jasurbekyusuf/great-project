import 'package:loadme_mobile/core/result/result.dart';

/// Single-method abstraction representing a piece of business logic.
///
/// Use cases live in the domain layer and orchestrate one or more repositories
/// to produce a [Result]. Controllers/notifiers depend on use cases, not on
/// repositories directly — keeping presentation independent of data sources.
///
/// ```dart
/// class LoginWithPhoneUseCase implements UseCase<LoginInput, AuthSession> {
///   LoginWithPhoneUseCase(this._repo);
///   final AuthRepository _repo;
///
///   @override
///   AsyncResult<AuthSession> call(LoginInput input) =>
///       _repo.login(phone: input.phone, password: input.password);
/// }
/// ```
abstract class UseCase<Input, Output> {
  const UseCase();

  /// Execute the use case asynchronously, returning a typed result.
  AsyncResult<Output> call(Input input);
}

/// Use case that takes no input — pass [NoInput.instance] when calling.
abstract class UseCaseNoInput<Output> {
  const UseCaseNoInput();

  AsyncResult<Output> call();
}

class NoInput {
  const NoInput._();
  static const NoInput instance = NoInput._();
}
