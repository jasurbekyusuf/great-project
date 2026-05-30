import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/shared/design_system/ds_card.dart';
import 'package:loadme_mobile/shared/design_system/ds_error_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_loader.dart';
import 'package:loadme_mobile/shared/widgets/app_scaffold.dart';
import 'package:loadme_mobile/features/trucks/presentation/controllers/trucks_controller.dart';

class TrucksScreen extends ConsumerWidget {
  const TrucksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trucksControllerProvider);
    return AppScaffold(
      title: 'Trucks',
      currentNavIndex: 0,
      actions: [
        IconButton(
            onPressed: () => context.push('/add-truck'),
            icon: const Icon(Icons.local_shipping_outlined)),
        IconButton(
            onPressed: () => context.push('/add-post-truck'),
            icon: const Icon(Icons.add)),
      ],
      body: state.when(
        loading: () => const DsLoader(),
        error: (e, _) => DsErrorState(message: e.toString()),
        data: (items) => ListView.builder(
          padding: EdgeInsets.all(context.space.lg),
          itemCount: items.length,
          itemBuilder: (_, i) => Padding(
            padding: EdgeInsets.only(bottom: context.space.md),
            child: GestureDetector(
              onTap: () => context.push('/post-truck/${items[i].guid}'),
              child: DsCard(
                  child:
                      Text('${items[i].fromAddress} -> ${items[i].toAddress}')),
            ),
          ),
        ),
      ),
    );
  }
}
