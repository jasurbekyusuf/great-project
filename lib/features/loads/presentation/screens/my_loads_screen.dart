import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/loads/domain/entities/load_entity.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_controller.dart';
import 'package:loadme_mobile/features/loads/presentation/widgets/load_figma_card.dart';
import 'package:loadme_mobile/shared/design_system/ds_confirmation_modal.dart';
import 'package:loadme_mobile/shared/design_system/ds_empty_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_error_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_loader.dart';
import 'package:loadme_mobile/shared/widgets/app_scaffold.dart';
import 'package:loadme_mobile/shared/widgets/mobile_segmented_tab.dart';
import 'package:loadme_mobile/shared/widgets/owner_action_sheet.dart';

class MyLoadsScreen extends ConsumerWidget {
  const MyLoadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myLoadsControllerProvider);
    final controller = ref.watch(myLoadsControllerProvider.notifier);
    final selectedIndex = controller.tab == MyLoadsTab.active ? 0 : 1;

    return AppScaffold(
      title: 'nav.myLoads'.tr(ref),
      currentNavIndex: 2,
      padded: false, // ListView already adds 16px horizontal — match Search screen.
      actions: [
        IconButton(onPressed: () => context.push('/add-load'), icon: const Icon(Icons.add)),
      ],
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(context.space.lg, context.space.md, context.space.lg, context.space.md),
            child: MobileSegmentedTab(
              items: ['myloads.tab.active'.tr(ref), 'myloads.tab.history'.tr(ref)],
              selectedIndex: selectedIndex,
              onChanged: (i) => ref
                  .read(myLoadsControllerProvider.notifier)
                  .setTab(i == 0 ? MyLoadsTab.active : MyLoadsTab.history),
            ),
          ),
          Expanded(
            child: state.when(
              loading: () => const DsLoader(),
              error: (e, _) => DsErrorState(
                message: e.toString(),
                onRetry: () => ref.read(myLoadsControllerProvider.notifier).refresh(),
              ),
              data: (items) => _MyLoadsList(
                items: items,
                isActiveTab: selectedIndex == 0,
                emptyTitle: (selectedIndex == 0 ? 'myloads.empty.active' : 'myloads.empty.history').tr(ref),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyLoadsList extends ConsumerWidget {
  const _MyLoadsList({
    required this.items,
    required this.isActiveTab,
    required this.emptyTitle,
  });

  final List<LoadEntity> items;
  final bool isActiveTab;
  final String emptyTitle;

  Future<void> _openActions(BuildContext context, WidgetRef ref, LoadEntity item) async {
    showOwnerActionSheet(
      context,
      title: '${item.fromAddress} → ${item.toAddress}',
      actions: [
        OwnerAction(
          icon: Icons.visibility_outlined,
          label: 'Ko\'rish',
          onTap: () => context.push('/my-load/${item.guid}?active=$isActiveTab'),
        ),
        if (isActiveTab)
          OwnerAction(
            icon: Icons.edit_outlined,
            label: 'Tahrirlash',
            onTap: () => context.push('/edit-load/${item.guid}'),
          ),
        OwnerAction(
          icon: isActiveTab ? Icons.inventory_2_outlined : Icons.refresh_rounded,
          label: isActiveTab ? 'Arxivlash' : 'Qayta faollashtirish',
          destructive: isActiveTab,
          onTap: () async {
            final ok = await showDsConfirmation(
              context,
              title: isActiveTab ? 'Arxivlash' : 'Faollashtirish',
              message: isActiveTab ? 'Yuk arxivga o\'tadi.' : 'Yuk yana faol bo\'ladi.',
              confirmText: isActiveTab ? 'Arxivlash' : 'Faollashtirish',
              cancelText: 'Bekor',
              intent: isActiveTab ? DsConfirmIntent.warning : DsConfirmIntent.primary,
              icon: isActiveTab ? Icons.inventory_2_outlined : Icons.refresh_rounded,
            );
            if (!ok) return;
            await ref.read(myLoadsControllerProvider.notifier).updateStatus(
                  guid: item.guid,
                  isActive: !isActiveTab,
                  closedPlatform: isActiveTab ? 'loadme' : null,
                );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) return DsEmptyState(title: emptyTitle);

    return RefreshIndicator(
      onRefresh: () => ref.read(myLoadsControllerProvider.notifier).refresh(),
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(context.space.lg, 0, context.space.lg, context.space.lg),
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(height: context.space.sm),
        itemBuilder: (_, index) {
          final item = items[index];
          return GestureDetector(
            onLongPress: () => _openActions(context, ref, item),
            child: LoadFigmaCard(
              load: item,
              distanceKm: 600 + index * 100,
              roleBadge: 'Admin',
              truckType: index.isEven ? 'Tent / Shtora' : 'Isuzu NQR / NPR',
              loadKind: "To'liq",
              priceLabel: 'common.negotiable'.tr(ref),
              onTap: () => context.push('/my-load/${item.guid}?active=$isActiveTab'),
            ),
          );
        },
      ),
    );
  }
}
