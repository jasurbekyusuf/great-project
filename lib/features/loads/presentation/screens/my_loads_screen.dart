import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_controller.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_display_providers.dart';
import 'package:loadme_mobile/features/loads/presentation/models/load_display.dart';
import 'package:loadme_mobile/features/loads/presentation/widgets/load_figma_card.dart';
import 'package:loadme_mobile/shared/design_system/ds_confirmation_modal.dart';
import 'package:loadme_mobile/shared/design_system/ds_illustration_empty.dart';
import 'package:loadme_mobile/shared/design_system/ds_error_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_loader.dart';
import 'package:loadme_mobile/shared/widgets/floating_market_nav.dart';
import 'package:loadme_mobile/shared/widgets/frosted_header.dart';
import 'package:loadme_mobile/shared/widgets/owner_action_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Figma "Mening yuklarim" (Yuk egasi section — empty 6780:10328 / filled
/// 6804:10991). A [FrostedHeader] over a list of [LoadFigmaCard] items with a
/// sticky full-width "Yuk qo’shish" CTA. The redesign drops the Faol/Tarix
/// segmented tab the old screen had — only active loads are shown.
class MyLoadsScreen extends ConsumerWidget {
  const MyLoadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myLoadsDisplayProvider);

    return Scaffold(
      backgroundColor: FigmaPalette.sheetBg,
      body: Column(
        children: [
          const FrostedHeader(title: 'Mening yuklarim'),
          Expanded(
            child: state.when(
              loading: () => const DsLoader(),
              error: (e, _) => DsErrorState(
                message: e.toString(),
                onRetry: () =>
                    ref.read(myLoadsControllerProvider.notifier).refresh(),
              ),
              data: (items) => _MyLoadsList(items: items),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyLoadsList extends ConsumerWidget {
  const _MyLoadsList({required this.items});

  final List<LoadDisplay> items;

  Future<void> _openActions(
      BuildContext context, WidgetRef ref, LoadDisplay d) async {
    final item = d.load;
    await showOwnerActionSheet(
      context,
      title: '${item.fromAddress} → ${item.toAddress}',
      actions: [
        OwnerAction(
          icon: Icons.visibility_outlined,
          label: 'owner.view'.tr(ref),
          onTap: () => context.push('/my-load/${item.guid}?active=true'),
        ),
        OwnerAction(
          icon: Icons.edit_outlined,
          label: 'common.edit'.tr(ref),
          onTap: () => context.push('/edit-load/${item.guid}'),
        ),
        OwnerAction(
          icon: Icons.inventory_2_outlined,
          label: 'owner.archive'.tr(ref),
          destructive: true,
          onTap: () async {
            final ok = await showDsConfirmation(
              context,
              title: 'owner.archive'.tr(ref),
              message: 'owner.archiveMessage'.tr(ref),
              confirmText: 'owner.archive'.tr(ref),
              cancelText: 'common.cancel'.tr(ref),
              intent: DsConfirmIntent.warning,
              icon: Icons.inventory_2_outlined,
            );
            if (!ok) return;
            await ref.read(myLoadsControllerProvider.notifier).updateStatus(
                  guid: item.guid,
                  isActive: false,
                  closedPlatform: 'loadme',
                );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      // Figma empty (6780:10328): box illustration → 8 → text → 40 → "Qo'shish".
      return DsIllustrationEmpty(
        asset: 'assets/images/empty_loads.png',
        message: 'myloads.empty.active'.tr(ref),
        gap: 8,
        actionLabel: 'common.add'.tr(ref),
        onAction: () => context.push('/add-load'),
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(myLoadsControllerProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                    onTap: () =>
                        context.push('/my-load/${d.load.guid}?active=true'),
                  ),
                );
              },
            ),
          ),
        ),
        // Sticky "+ Yuk qo’shish" CTA, lifted to clear the floating nav.
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                16, 8, 16, FloatingMarketNav.reservedHeight),
            child: _AddLoadButton(onTap: () => context.push('/add-load')),
          ),
        ),
      ],
    );
  }
}

class _AddLoadButton extends StatelessWidget {
  const _AddLoadButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FigmaPalette.primary,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.plus, size: 20, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Yuk qo’shish',
                style: TextStyle(
                  fontSize: 16,
                  height: 20 / 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
