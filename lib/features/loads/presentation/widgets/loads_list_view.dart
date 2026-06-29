import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_controller.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_display_providers.dart';
import 'package:loadme_mobile/features/loads/presentation/widgets/load_figma_card.dart';
import 'package:loadme_mobile/shared/design_system/ds_error_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_loader.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Pure list — does not own the header, tab switcher, or filters block.
/// Embedded inside `MarketScreen` so tab swap doesn't rebuild the chrome.
class LoadsListView extends ConsumerWidget {
  const LoadsListView({
    super.key,
    required this.guest,
    this.nearbyTitle,
    this.nearbyFilters,
  });
  final bool guest;

  /// Origin label for the empty-state "{origin}ga yaqin yuklar" fallback feed
  /// (null when no Qidiruv origin is set — the fallback section then hides).
  final String? nearbyTitle;

  /// Pickup-only server filter (origin) backing that fallback feed.
  final Map<String, String>? nearbyFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.space;
    final state = ref.watch(loadsDisplayProvider);

    return state.when(
      loading: () => const DsLoader(),
      error: (e, _) => DsErrorState(
        message: e.toString(),
        onRetry: () => ref.read(loadsControllerProvider.notifier).refresh(),
      ),
      data: (items) {
        if (items.isEmpty) {
          return _NotFound(
            guest: guest,
            nearbyTitle: nearbyTitle,
            nearbyFilters: nearbyFilters,
          );
        }
        final notifier = ref.read(loadsControllerProvider.notifier);
        final hasMore = notifier.hasMore;
        return RefreshIndicator(
          onRefresh: () => notifier.refresh(),
          // Fire `loadMore` ~400px before the bottom so the next page is already
          // arriving by the time the user reaches the current tail.
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.axis == Axis.vertical &&
                  n.metrics.pixels >= n.metrics.maxScrollExtent - 400) {
                notifier.loadMore();
              }
              return false;
            },
            child: ListView.separated(
              // Bottom inset clears the floating frosted nav (≈110px).
              padding: EdgeInsets.fromLTRB(s.lg, 0, s.lg, 110),
              // One extra row for the tail spinner while more pages exist.
              itemCount: items.length + (hasMore ? 1 : 0),
              separatorBuilder: (_, __) => SizedBox(height: s.sm),
              itemBuilder: (_, i) {
                if (i >= items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final d = items[i];
                return LoadFigmaCard(
                  load: d.load,
                  ownerName: d.ownerName,
                  ownerRating: d.ownerRating,
                  verified: d.verified,
                  roleBadge: d.roleBadge,
                  fromCountry: d.fromCountry,
                  toCountry: d.toCountry,
                  truckType: d.truckType,
                  weightT: d.weightT,
                  distanceKm: d.distanceKm,
                  radiusKm: d.radiusKm,
                  timeAgo: d.timeAgo,
                  priceLabel: d.priceLabel,
                  onTap: () => context.push(
                    guest
                        ? '/guest-load/${d.load.guid}'
                        : '/loads/${d.load.guid}',
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// "Yuklar topilmadi" — rich not-found state (Figma 6435:39539).
//
// Three stacked blocks mirroring the design frame:
//   • empty illustration       : 32px grey package glyph + title / subtitle
//   • Magnit promo card         : white r12, magnet glyph, green "Yoqish" CTA
//   • "{origin}ga yaqin yuklar" : real pickup-only fallback feed, hidden when
//      the search had no origin or that query returns empty / loading / error
//
// The empty block is inset an extra 16px each side (Figma `Frame 2087329727`
// padding) so the Magnit card lands at 311 wide, while the nearby
// `LoadFigmaCard`s keep the full 343 list width.
// ---------------------------------------------------------------------------

class _NotFound extends ConsumerWidget {
  const _NotFound({
    required this.guest,
    this.nearbyTitle,
    this.nearbyFilters,
  });

  final bool guest;
  final String? nearbyTitle;
  final Map<String, String>? nearbyFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Real "loads near the pickup" fallback — only when a Qidiruv origin was
    // set. Loading / error / empty all collapse to null so the section simply
    // hides rather than showing a header with no cards beneath it.
    final nearby = (nearbyTitle != null && nearbyFilters != null)
        ? ref
            .watch(nearbyLoadsProvider(loadsFilterKey(nearbyFilters!)))
            .valueOrNull
        : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        // ── Empty block (Figma `Frame 2087329727`): extra 16px inset, T/B 20
        //    pad, 16px gap between the centred caption and the Magnit card.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  const Icon(
                    LucideIcons.package,
                    size: 32,
                    color: FigmaPalette.gray700,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'loads.notFound.title'.tr(ref),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 18 / 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF566075),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'loads.notFound.subtitle'.tr(ref),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 18 / 12,
                      fontWeight: FontWeight.w500,
                      color: FigmaPalette.gray700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _MagnitCard(),
            ],
          ),
        ),
        // ── "{origin}ga yaqin yuklar" — real fallback feed (hidden if empty).
        if (nearby != null && nearby.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'loads.nearbyTitle'.tr(ref).replaceFirst('{place}', nearbyTitle!),
            style: const TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w500,
              color: FigmaPalette.countLabel,
            ),
          ),
          const SizedBox(height: 8),
          for (final d in nearby) ...[
            LoadFigmaCard(
              load: d.load,
              ownerName: d.ownerName,
              ownerRating: d.ownerRating,
              verified: d.verified,
              roleBadge: d.roleBadge,
              fromCountry: d.fromCountry,
              toCountry: d.toCountry,
              truckType: d.truckType,
              weightT: d.weightT,
              distanceKm: d.distanceKm,
              radiusKm: d.radiusKm,
              timeAgo: d.timeAgo,
              priceLabel: d.priceLabel,
              onTap: () => context.push(
                guest ? '/guest-load/${d.load.guid}' : '/loads/${d.load.guid}',
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

// Magnit promo (Figma `Container` 6435:39573) — white r12 card (no border):
// magnet glyph + "Magnit", a notify prompt, then the green "Yoqish" CTA.
class _MagnitCard extends ConsumerWidget {
  const _MagnitCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.magnet,
                  size: 20,
                  color: FigmaPalette.inkStrong,
                ),
                const SizedBox(width: 8),
                Text(
                  'magnit.title'.tr(ref),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w600,
                    color: FigmaPalette.inkStrong,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'loads.magnitPromo.body'.tr(ref),
              style: const TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w400,
                color: FigmaPalette.inkStrong,
              ),
            ),
            const SizedBox(height: 12),
            Material(
              color: FigmaPalette.moneyGreen,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => context.push('/magnit'),
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 40,
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      'loads.magnitPromo.enable'.tr(ref),
                      style: const TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
