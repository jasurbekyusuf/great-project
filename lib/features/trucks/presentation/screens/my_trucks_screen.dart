import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/trucks/domain/entities/truck_entity.dart';
import 'package:loadme_mobile/features/trucks/presentation/controllers/trucks_controller.dart';
import 'package:loadme_mobile/shared/design_system/ds_card.dart';
import 'package:loadme_mobile/shared/design_system/ds_confirmation_modal.dart';
import 'package:loadme_mobile/shared/design_system/ds_empty_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_error_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_loader.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/shared/widgets/app_scaffold.dart';
import 'package:loadme_mobile/shared/widgets/mobile_segmented_tab.dart';
import 'package:loadme_mobile/shared/widgets/owner_action_sheet.dart';

class MyTrucksScreen extends ConsumerWidget {
  const MyTrucksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myTrucksControllerProvider);
    final controller = ref.watch(myTrucksControllerProvider.notifier);
    final selectedIndex = switch (controller.tab) {
      MyTrucksTab.available => 0,
      MyTrucksTab.myTrucks => 1,
      MyTrucksTab.history => 2,
    };

    return AppScaffold(
      title: 'nav.myTrucks'.tr(ref),
      currentNavIndex: 2,
      padded: false,
      actions: [
        IconButton(
            onPressed: () => context.push('/add-truck'),
            icon: const Icon(Icons.local_shipping_outlined)),
        IconButton(
            onPressed: () => context.push('/add-post-truck'),
            icon: const Icon(Icons.add)),
      ],
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
                context.space.lg, context.space.lg, context.space.lg, 0),
            child: MobileSegmentedTab(
              items: [
                'mytrucks.tab.available'.tr(ref),
                'mytrucks.tab.my'.tr(ref),
                'mytrucks.tab.history'.tr(ref),
              ],
              selectedIndex: selectedIndex,
              variant: MobileSegmentedTabVariant.primaryFilled,
              onChanged: (index) {
                final next = switch (index) {
                  0 => MyTrucksTab.available,
                  1 => MyTrucksTab.myTrucks,
                  _ => MyTrucksTab.history,
                };
                ref.read(myTrucksControllerProvider.notifier).setTab(next);
              },
            ),
          ),
          Expanded(
            child: state.when(
              loading: () => const DsLoader(),
              error: (e, _) => DsErrorState(
                message: e.toString(),
                onRetry: () =>
                    ref.read(myTrucksControllerProvider.notifier).refresh(),
              ),
              data: (items) => _MyTrucksList(
                items: items,
                tab: controller.tab,
                emptyTitle: switch (controller.tab) {
                  MyTrucksTab.available => 'mytrucks.empty.available'.tr(ref),
                  MyTrucksTab.myTrucks => 'mytrucks.empty.my'.tr(ref),
                  MyTrucksTab.history => 'mytrucks.empty.history'.tr(ref),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyTrucksList extends ConsumerWidget {
  const _MyTrucksList({
    required this.items,
    required this.tab,
    required this.emptyTitle,
  });

  final List<TruckEntity> items;
  final MyTrucksTab tab;
  final String emptyTitle;

  Future<void> _openActions(BuildContext context, WidgetRef ref, TruckEntity item, bool isTruckTab) async {
    final isActive = tab == MyTrucksTab.available || tab == MyTrucksTab.myTrucks;
    await showOwnerActionSheet(
      context,
      title: '${item.fromAddress} → ${item.toAddress}',
      actions: [
        OwnerAction(
          icon: Icons.visibility_outlined,
          label: 'owner.view'.tr(ref),
          onTap: () => context.push(
            isTruckTab
                ? '/my-truck/${item.guid}?active=true'
                : '/my-post-truck-detail/${item.guid}?active=$isActive',
          ),
        ),
        OwnerAction(
          icon: Icons.edit_outlined,
          label: 'common.edit'.tr(ref),
          onTap: () => context.push(
            isTruckTab ? '/edit-truck/${item.guid}' : '/edit-post-truck/${item.guid}',
          ),
        ),
        OwnerAction(
          icon: isActive ? Icons.inventory_2_outlined : Icons.refresh_rounded,
          label: (isActive ? 'owner.archive' : 'owner.reactivate').tr(ref),
          destructive: isActive,
          onTap: () async {
            final ok = await showDsConfirmation(
              context,
              title: (isActive ? 'owner.archive' : 'owner.reactivate').tr(ref),
              message: (isActive ? 'detail.archiveTruckMessage' : 'detail.reactivateMessage').tr(ref),
              confirmText: (isActive ? 'owner.archive' : 'owner.reactivate').tr(ref),
              cancelText: 'common.cancel'.tr(ref),
              intent: isActive ? DsConfirmIntent.warning : DsConfirmIntent.primary,
              icon: isActive ? Icons.inventory_2_outlined : Icons.refresh_rounded,
            );
            if (!ok) return;
            final controller = ref.read(myTrucksControllerProvider.notifier);
            if (isTruckTab) {
              await controller.updateTruckStatus(guid: item.guid, isActive: !isActive);
            } else {
              await controller.updatePostTruckStatus(guid: item.guid, isActive: !isActive);
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) return DsEmptyState(title: emptyTitle);

    return RefreshIndicator(
      onRefresh: () => ref.read(myTrucksControllerProvider.notifier).refresh(),
      child: ListView.separated(
        padding: EdgeInsets.all(context.space.lg),
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(height: context.space.md),
        itemBuilder: (_, index) {
          final item = items[index];
          final isTruckTab = tab == MyTrucksTab.myTrucks;
          return GestureDetector(
            onTap: () => context.push(
              isTruckTab
                  ? '/my-truck/${item.guid}?active=true'
                  : '/my-post-truck-detail/${item.guid}?active=${tab == MyTrucksTab.available}',
            ),
            onLongPress: () => _openActions(context, ref, item, isTruckTab),
            child: DsCard(
              child: Row(
                children: [
                  Icon(
                    isTruckTab
                        ? Icons.local_shipping_outlined
                        : Icons.route_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: context.space.md),
                  Expanded(
                    child: Text(
                      '${item.fromAddress} -> ${item.toAddress}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
