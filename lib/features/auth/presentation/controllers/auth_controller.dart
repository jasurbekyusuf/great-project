import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/config/env/app_env.dart';
import 'package:loadme_mobile/core/errors/app_failure.dart';
import 'package:loadme_mobile/core/logging/app_logger.dart';
import 'package:loadme_mobile/core/network/dio_client.dart';
import 'package:loadme_mobile/core/storage/providers.dart';
import 'package:loadme_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:loadme_mobile/features/auth/data/datasources/fake_auth_remote_data_source.dart';
import 'package:loadme_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:loadme_mobile/features/auth/domain/entities/auth_check_result.dart';
import 'package:loadme_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:loadme_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:loadme_mobile/features/auth/domain/use_cases/check_user_phone_use_case.dart';
import 'package:loadme_mobile/features/auth/domain/use_cases/get_cached_session_use_case.dart';
import 'package:loadme_mobile/features/auth/domain/use_cases/login_use_case.dart';
import 'package:loadme_mobile/features/auth/domain/use_cases/logout_use_case.dart';
import 'package:loadme_mobile/features/auth/domain/use_cases/register_use_case.dart';
import 'package:loadme_mobile/features/auth/domain/use_cases/verify_otp_use_case.dart';

// -----------------------------------------------------------------------------
// DI wiring (data + domain)
// -----------------------------------------------------------------------------

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  if (ref.watch(appEnvProvider).useFakeData) return FakeAuthRemoteDataSource();
  return AuthRemoteDataSource(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(storageProvider),
    ref.watch(secureTokenStorageProvider),
  ),
);

// Use cases — one provider per use case so they can be swapped in tests.
final loginUseCaseProvider =
    Provider((ref) => LoginUseCase(ref.watch(authRepositoryProvider)));
final checkUserPhoneUseCaseProvider =
    Provider((ref) => CheckUserPhoneUseCase(ref.watch(authRepositoryProvider)));
final verifyOtpUseCaseProvider =
    Provider((ref) => VerifyOtpUseCase(ref.watch(authRepositoryProvider)));
final registerUseCaseProvider =
    Provider((ref) => RegisterUseCase(ref.watch(authRepositoryProvider)));
final logoutUseCaseProvider =
    Provider((ref) => LogoutUseCase(ref.watch(authRepositoryProvider)));
final getCachedSessionUseCaseProvider =
    Provider((ref) => GetCachedSessionUseCase(ref.watch(authRepositoryProvider)));

// -----------------------------------------------------------------------------
// Controller
// -----------------------------------------------------------------------------

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

/// Thin presentation layer that drives use cases and projects results into
/// [AsyncValue] for the UI. Never touches data sources directly.
class AuthController extends AsyncNotifier<AuthSession?> {
  static final _log = AppLogger.tagged('AuthController');

  @override
  Future<AuthSession?> build() async {
    final result = await ref.read(getCachedSessionUseCaseProvider).call();
    return result.fold(
      (f) {
        _log.w('No cached session: $f');
        return null;
      },
      (session) => session,
    );
  }

  Future<AppFailure?> login(String phone, String password) async {
    state = const AsyncLoading();
    final result = await ref
        .read(loginUseCaseProvider)
        .call(LoginInput(phone: phone, password: password));
    return result.fold(
      (f) {
        state = AsyncError(f, StackTrace.current);
        return f;
      },
      (s) {
        state = AsyncData(s);
        return null;
      },
    );
  }

  Future<(AuthCheckResult?, AppFailure?)> checkUserPhone(String phone) async {
    final result = await ref.read(checkUserPhoneUseCaseProvider).call(phone);
    return result.fold((f) => (null, f), (r) => (r, null));
  }

  Future<(AuthSession?, AppFailure?)> verifyOtp({
    required String phone,
    required String smsId,
    required String otp,
    required bool userFound,
  }) async {
    final result = await ref.read(verifyOtpUseCaseProvider).call(
          VerifyOtpInput(phone: phone, smsId: smsId, otp: otp, userFound: userFound),
        );
    return result.fold((f) => (null, f), (session) {
      if (session != null) state = AsyncData(session);
      return (session, null);
    });
  }

  Future<(AuthSession?, AppFailure?)> register({
    required String fullName,
    String? companyName,
    required String phone,
    required String smsId,
    required String otp,
  }) async {
    final result = await ref.read(registerUseCaseProvider).call(
          RegisterInput(
            fullName: fullName,
            companyName: companyName,
            phone: phone,
            smsId: smsId,
            otp: otp,
          ),
        );
    return result.fold((f) => (null, f), (session) {
      state = AsyncData(session);
      return (session, null);
    });
  }

  Future<AppFailure?> logout() async {
    final result = await ref.read(logoutUseCaseProvider).call();
    return result.fold(
      (f) => f,
      (_) {
        state = const AsyncData(null);
        return null;
      },
    );
  }
}
