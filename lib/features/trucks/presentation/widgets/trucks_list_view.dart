import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/core/utils/address_format.dart';
import 'package:loadme_mobile/features/trucks/presentation/controllers/trucks_controller.dart';
import 'package:loadme_mobile/features/trucks/presentation/controllers/trucks_display_providers.dart';
import 'package:loadme_mobile/features/trucks/presentation/widgets/truck_figma_card.dart';
import 'package:loadme_mobile/shared/design_system/ds_empty_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_error_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_loader.dart';

/// Pure list — embedded inside `MarketScreen`. Uses the dedicated
/// `TruckFigmaCard` (avatar + truck model + "To'liq" footer chip).
class TrucksListView extends ConsumerWidget {
  const TrucksListView({super.key, required this.guest});
  final bool guest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.space;
    final state = ref.watch(trucksDisplayProvider);

    return state.when(
      loading: () => const DsLoader(),
      error: (e, _) => DsErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(trucksControllerProvider),
      ),
      data: (items) {
        if (items.isEmpty) return DsEmptyState(title: 'common.notFound'.tr(ref));
        final notifier = ref.read(trucksControllerProvider.notifier);
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
                return TruckFigmaCard(
                  truckName: d.truckType,
                  priceLabel: d.priceLabel,
                  fromCity: addressCity(d.truck.fromAddress),
                  fromCountry: d.fromCountry,
                  toCity: addressCity(d.truck.toAddress),
                  toCountry: d.toCountry,
                  distanceKm: d.distanceKm,
                  weightT: d.weightT,
                  loadKind: d.loadKind,
                  timeAgo: d.timeAgo,
                  onTap: () => context.push(
                    guest
                        ? '/guest-post-truck/${d.truck.guid}'
                        : '/post-truck/${d.truck.guid}',
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
