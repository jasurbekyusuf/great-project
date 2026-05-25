import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/network/dio_client.dart';
import 'package:loadme_mobile/core/storage/providers.dart';
import 'package:loadme_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:loadme_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:loadme_mobile/features/auth/domain/entities/auth_check_result.dart';
import 'package:loadme_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:loadme_mobile/features/auth/domain/repositories/auth_repository.dart';

final authRemoteDataSourceProvider = Provider((ref) => AuthRemoteDataSource(ref.watch(dioProvider)));

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider), ref.watch(storageProvider)),
);

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

class AuthController extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() {
    return ref.read(authRepositoryProvider).getCachedSession();
  }

  Future<void> login(String phone, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).login(phone: phone, password: password));
  }

  Future<AuthCheckResult> checkUserPhone(String phone) {
    return ref.read(authRepositoryProvider).checkUserPhone(phone);
  }

  Future<AuthSession?> verifyOtp({
    required String phone,
    required String smsId,
    required String otp,
    required bool userFound,
  }) async {
    final session = await ref
        .read(authRepositoryProvider)
        .verifyOtp(phone: phone, smsId: smsId, otp: otp, userFound: userFound);
    if (session != null) {
      state = AsyncData(session);
    }
    return session;
  }

  Future<AuthSession> register({
    required String fullName,
    String? companyName,
    required String phone,
    required String smsId,
    required String otp,
  }) async {
    final session = await ref.read(authRepositoryProvider).register(
          fullName: fullName,
          companyName: companyName,
          phone: phone,
          smsId: smsId,
          otp: otp,
        );
    state = AsyncData(session);
    return session;
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}
