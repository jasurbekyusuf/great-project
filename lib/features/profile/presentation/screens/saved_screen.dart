import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/features/loads/presentation/widgets/load_figma_card.dart';
import 'package:loadme_mobile/features/saved/presentation/providers/saved_providers.dart';
import 'package:loadme_mobile/shared/design_system/ds_error_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_loader.dart';
import 'package:loadme_mobile/shared/widgets/frosted_section_header.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Figma "Saqlanganlar" (7088:15906) — a frosted header over a vertical list
/// (gap 8) of saved load cards. The card is the very same component used on the
/// Search / market screen ([LoadFigmaCard]), so saved loads render identically.
///
/// Driven by the real `/favorites/` endpoint via [savedControllerProvider]:
/// tapping a card opens the load detail (where the bookmark un-saves it).
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(savedControllerProvider);
    final controller = ref.read(savedControllerProvider.notifier);

    return Scaffold(
      backgroundColor: FigmaPalette.sheetBg,
      body: Column(
        children: [
          FrostedSectionHeader(title: 'profile.saved'.tr(ref)),
          Expanded(
            child: async.when(
              loading: () => const DsLoader(),
              error: (e, _) => DsErrorState(
                message: e.toString(),
                onRetry: controller.refresh,
              ),
              data: (items) => items.isEmpty
                  ? _Empty(onRefresh: controller.refresh)
                  : RefreshIndicator(
                      color: FigmaPalette.primary,
                      onRefresh: controller.refresh,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final load = items[i].load;
                          return LoadFigmaCard(
                            load: load,
                            ownerName: load.ownerName ?? 'LoadMe',
                            ownerRating: load.ownerRating,
                            verified: load.verified,
                            roleBadge: load.roleBadge,
                            fromCountry: load.fromCountry ?? '',
                            toCountry: load.toCountry ?? '',
                            truckType: load.truckType ?? '—',
                            weightT: load.weightT,
                            volumeM3: load.volumeM3,
                            distanceKm: load.distanceKm,
                            radiusKm: load.radiusKm,
                            timeAgo: load.timeAgo,
                            priceLabel: load.priceLabel,
                            onTap: () => context.push('/loads/${load.guid}'),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty "Saqlanganlar" state — kept scrollable so pull-to-refresh still works.
class _Empty extends ConsumerWidget {
  const _Empty({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: FigmaPalette.primary,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
        children: [
          const Icon(
              LucideIcons.bookmark, size: 56, color: FigmaPalette.inkMuted),
          const SizedBox(height: 12),
          Text(
            'saved.empty.title'.tr(ref),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              height: 22 / 16,
              fontWeight: FontWeight.w600,
              color: FigmaPalette.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'saved.empty.subtitle'.tr(ref),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 18 / 13,
              fontWeight: FontWeight.w500,
              color: FigmaPalette.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
