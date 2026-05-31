import 'package:loadme_mobile/core/result/result.dart';
import 'package:loadme_mobile/core/use_case/use_case.dart';
import 'package:loadme_mobile/features/auth/domain/entities/auth_check_result.dart';
import 'package:loadme_mobile/features/auth/domain/repositories/auth_repository.dart';

/// Verifies whether a phone is registered and triggers an OTP SMS.
///
/// Wraps a single repository call so presentation never reaches for the
/// repository directly — keeping a stable, testable contract.
class CheckUserPhoneUseCase implements UseCase<String, AuthCheckResult> {
  const CheckUserPhoneUseCase(this._repository);
  final AuthRepository _repository;

  @override
  AsyncResult<AuthCheckResult> call(String phone) =>
      _repository.checkUserPhone(phone.trim());
}
