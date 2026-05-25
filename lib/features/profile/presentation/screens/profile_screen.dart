import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';
import 'package:loadme_mobile/shared/design_system/ds_card.dart';
import 'package:loadme_mobile/shared/design_system/ds_error_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_loader.dart';
import 'package:loadme_mobile/shared/widgets/app_scaffold.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileControllerProvider);

    return AppScaffold(
      title: 'Profile',
      currentNavIndex: 2,
      body: state.when(
        loading: () => const DsLoader(),
        error: (e, _) => DsErrorState(message: e.toString()),
        data: (profile) => Padding(
          padding: EdgeInsets.all(context.space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.fullName, style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: context.space.sm),
                    Text(profile.phone ?? '-', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Spacer(),
              DsButton(
                label: 'Logout',
                onPressed: () async {
                  await ref.read(profileControllerProvider.notifier).logout();
                  if (context.mounted) context.go('/auth/welcome');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
