import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_controller.dart';
import 'package:loadme_mobile/shared/design_system/ds_card.dart';
import 'package:loadme_mobile/shared/design_system/ds_empty_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_error_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_loader.dart';
import 'package:loadme_mobile/shared/widgets/app_scaffold.dart';

class LoadsScreen extends ConsumerWidget {
  const LoadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loadsControllerProvider);

    return AppScaffold(
      title: 'Loads',
      currentNavIndex: 0,
      actions: [
        IconButton(onPressed: () => context.push('/loads/filters'), icon: const Icon(Icons.tune)),
        IconButton(onPressed: () => context.push('/loads/add'), icon: const Icon(Icons.add)),
      ],
      body: state.when(
        loading: () => const DsLoader(),
        error: (e, _) => DsErrorState(message: e.toString(), onRetry: () => ref.read(loadsControllerProvider.notifier).refresh()),
        data: (items) {
          if (items.isEmpty) return const DsEmptyState(title: 'No loads found');
          return RefreshIndicator(
            onRefresh: () => ref.read(loadsControllerProvider.notifier).refresh(),
            child: ListView.separated(
              padding: EdgeInsets.all(context.space.lg),
              itemCount: items.length,
              separatorBuilder: (_, __) => SizedBox(height: context.space.md),
              itemBuilder: (_, i) {
                final item = items[i];
                return GestureDetector(
                  onTap: () => context.push('/loads/${item.guid}'),
                  child: DsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item.fromAddress} -> ${item.toAddress}', style: Theme.of(context).textTheme.titleMedium),
                        SizedBox(height: context.space.xs),
                        Text(item.comment ?? '-', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
