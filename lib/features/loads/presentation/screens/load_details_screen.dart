import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_controller.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';
import 'package:loadme_mobile/shared/design_system/ds_card.dart';
import 'package:loadme_mobile/shared/design_system/ds_error_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_loader.dart';
import 'package:loadme_mobile/shared/widgets/app_scaffold.dart';

class LoadDetailsScreen extends ConsumerWidget {
  const LoadDetailsScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loadDetailsProvider(id));

    return AppScaffold(
      title: 'Load Details',
      actions: [
        IconButton(onPressed: () => context.push('/loads/$id/edit'), icon: const Icon(Icons.edit_outlined)),
      ],
      body: state.when(
        loading: () => const DsLoader(),
        error: (e, _) => DsErrorState(message: e.toString()),
        data: (load) => Padding(
          padding: EdgeInsets.all(context.space.lg),
          child: DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${load.fromAddress} -> ${load.toAddress}', style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: context.space.md),
                Text(load.comment ?? '-', style: Theme.of(context).textTheme.bodyLarge),
                if (load.price != null) ...[
                  SizedBox(height: context.space.md),
                  Text('Price: ${load.price}', style: Theme.of(context).textTheme.titleMedium),
                ],
                const Spacer(),
                DsButton(label: 'Back to loads', onPressed: () => context.go('/loads')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
