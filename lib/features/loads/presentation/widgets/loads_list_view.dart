import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  const LoadsListView({super.key, required this.guest});
  final bool guest;

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
        if (items.isEmpty) return const _NotFound();
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
// "Yuklar topilmadi" — rich not-found state (Figma 6435:39539): illustration,
// message and a Magnit-alert promo. The nearby-loads fallback list is omitted —
// it needs a "loads near origin" query the controller doesn't expose yet.
// ---------------------------------------------------------------------------

class _NotFound extends StatelessWidget {
  const _NotFound();

  static const _green = Color(0xFF17B26A);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 110),
      children: [
        Icon(LucideIcons.package, size: 56, color: c.textMuted),
        const SizedBox(height: 12),
        Text(
          'Yuklar topilmadi',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            height: 22 / 16,
            fontWeight: FontWeight.w600,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Qidiruvingizga mos yuklar topilmadi.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 18 / 13,
            fontWeight: FontWeight.w500,
            color: c.textMuted,
          ),
        ),
        const SizedBox(height: 20),
        DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/magnit_badge.png',
                      width: 28,
                      height: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Magnit',
                      style: TextStyle(
                        fontSize: 16,
                        height: 22 / 16,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Bu yo’nalishda yangi yuklar chiqishi bilan xabar beraylikmi?',
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  color: _green,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => context.push('/magnit'),
                    borderRadius: BorderRadius.circular(12),
                    child: const SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: Center(
                        child: Text(
                          'Yoqish',
                          style: TextStyle(
                            fontSize: 16,
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
        ),
      ],
    );
  }
}
