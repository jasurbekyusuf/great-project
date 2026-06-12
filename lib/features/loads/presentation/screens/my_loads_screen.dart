import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_controller.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_display_providers.dart';
import 'package:loadme_mobile/features/loads/presentation/models/load_display.dart';
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
    final state = ref.watch(myLoadsDisplayProvider);
    final controller = ref.watch(myLoadsControllerProvider.notifier);
    final selectedIndex = controller.tab == MyLoadsTab.active ? 0 : 1;

    return AppScaffold(
      title: 'nav.myLoads'.tr(ref),
      // Tab root inside StatefulShellRoute — there's nothing for back to pop.
      showBack: false,
      // Bottom nav provided by ScaffoldWithNav.
      padded: false, // ListView already adds 16px horizontal — match Search screen.
      actions: [
        IconButton(onPressed: () => context.push('/add-load'), icon: const Icon(Icons.add)),
      ],
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(context.space.lg, context.space.md, context.space.lg, context.space.md),
            // Web uses default CustomTab (white pill on gray). No blue variant.
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

  final List<LoadDisplay> items;
  final bool isActiveTab;
  final String emptyTitle;

  Future<void> _openActions(BuildContext context, WidgetRef ref, LoadDisplay d) async {
    final item = d.load;
    await showOwnerActionSheet(
      context,
      title: '${item.fromAddress} → ${item.toAddress}',
      actions: [
        OwnerAction(
          icon: Icons.visibility_outlined,
          label: 'owner.view'.tr(ref),
          onTap: () => context.push('/my-load/${item.guid}?active=$isActiveTab'),
        ),
        if (isActiveTab)
          OwnerAction(
            icon: Icons.edit_outlined,
            label: 'common.edit'.tr(ref),
            onTap: () => context.push('/edit-load/${item.guid}'),
          ),
        OwnerAction(
          icon: isActiveTab ? Icons.inventory_2_outlined : Icons.refresh_rounded,
          label: (isActiveTab ? 'owner.archive' : 'owner.reactivate').tr(ref),
          destructive: isActiveTab,
          onTap: () async {
            final ok = await showDsConfirmation(
              context,
              title: (isActiveTab ? 'owner.archive' : 'owner.reactivate').tr(ref),
              message: (isActiveTab ? 'owner.archiveMessage' : 'owner.reactivateMessage').tr(ref),
              confirmText: (isActiveTab ? 'owner.archive' : 'owner.reactivate').tr(ref),
              cancelText: 'common.cancel'.tr(ref),
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
          final d = items[index];
          return GestureDetector(
            onLongPress: () => _openActions(context, ref, d),
            child: LoadFigmaCard(
              load: d.load,
              ownerName: d.ownerName,
              ownerRating: d.ownerRating,
              fromCountry: d.fromCountry,
              toCountry: d.toCountry,
              deadHeadKm: d.deadHeadKm,
              volumeM3: d.volumeM3,
              weightT: d.weightT,
              distanceKm: d.distanceKm,
              loadKind: d.loadKind,
              priceLabel: d.priceLabel,
              timeAgo: d.timeAgo,
              onTap: () => context.push('/my-load/${d.load.guid}?active=$isActiveTab'),
            ),
          );
        },
      ),
    );
  }
}
