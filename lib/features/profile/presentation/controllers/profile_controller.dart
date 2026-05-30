import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/config/env/app_env.dart';
import 'package:loadme_mobile/core/network/dio_client.dart';
import 'package:loadme_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:loadme_mobile/features/profile/data/datasources/fake_profile_remote_data_source.dart';
import 'package:loadme_mobile/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:loadme_mobile/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:loadme_mobile/features/profile/domain/entities/profile_entity.dart';

final profileControllerProvider = AutoDisposeAsyncNotifierProvider<ProfileController, ProfileEntity>(ProfileController.new);

class ProfileController extends AutoDisposeAsyncNotifier<ProfileEntity> {
  @override
  Future<ProfileEntity> build() {
    final useFake = ref.watch(appEnvProvider).useFakeData;
    final ds = useFake ? FakeProfileRemoteDataSource() : ProfileRemoteDataSource(ref.watch(dioProvider));
    return ProfileRepositoryImpl(ds).getProfile();
  }

  Future<void> logout() => ref.read(authControllerProvider.notifier).logout();
}
