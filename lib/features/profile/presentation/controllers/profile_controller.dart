import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/errors/app_failure.dart';
import 'package:loadme_mobile/core/network/dio_client.dart';
import 'package:loadme_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:loadme_mobile/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:loadme_mobile/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:loadme_mobile/features/profile/domain/entities/profile_entity.dart';
import 'package:loadme_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:loadme_mobile/features/profile/domain/use_cases/get_profile_use_case.dart';
import 'package:loadme_mobile/features/profile/domain/use_cases/update_profile_use_case.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(ProfileRemoteDataSource(ref.watch(dioProvider))),
);

final getProfileUseCaseProvider =
    Provider((ref) => GetProfileUseCase(ref.watch(profileRepositoryProvider)));

final updateProfileUseCaseProvider = Provider(
    (ref) => UpdateProfileUseCase(ref.watch(profileRepositoryProvider)));

final profileControllerProvider =
    AutoDisposeAsyncNotifierProvider<ProfileController, ProfileEntity>(
        ProfileController.new);

class ProfileController extends AutoDisposeAsyncNotifier<ProfileEntity> {
  @override
  Future<ProfileEntity> build() async {
    final result = await ref.read(getProfileUseCaseProvider).call();
    return result.fold((f) => throw f, (e) => e);
  }

  /// Persists edited profile fields. On success the freshly-parsed user is
  /// pushed into [state] so the Profile screen reflects the change without a
  /// refetch; returns the failure (or `null` on success) so the edit screen can
  /// surface an inline error.
  Future<AppFailure?> updateProfile(UpdateProfileInput input) async {
    final result = await ref.read(updateProfileUseCaseProvider).call(input);
    return result.fold(
      (f) => f,
      (updated) {
        state = AsyncData(updated);
        return null;
      },
    );
  }

  Future<void> logout() async {
    await ref.read(authControllerProvider.notifier).logout();
  }
}
