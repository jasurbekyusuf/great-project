import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/loads/domain/entities/load_entity.dart';
import 'package:loadme_mobile/features/loads/presentation/widgets/load_figma_card.dart';
import 'package:loadme_mobile/features/trucks/presentation/controllers/trucks_controller.dart';
import 'package:loadme_mobile/features/trucks/presentation/controllers/trucks_display_providers.dart';
import 'package:loadme_mobile/shared/design_system/ds_empty_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_error_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_loader.dart';

/// Pure list — embedded inside `MarketScreen`. Reuses `LoadFigmaCard` via a
/// `LoadEntity` adapter so the visual design is identical to the loads tab.
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
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(trucksControllerProvider),
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(s.lg, 0, s.lg, s.lg),
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(height: s.sm),
            itemBuilder: (_, i) {
              final d = items[i];
              final asLoad = LoadEntity(
                guid: d.truck.guid,
                fromAddress: d.truck.fromAddress,
                toAddress: d.truck.toAddress,
                pickupDate: d.pickupDateIso,
              );
              return LoadFigmaCard(
                load: asLoad,
                ownerName: d.ownerName,
                fromCountry: d.fromCountry,
                toCountry: d.toCountry,
                volumeM3: d.volumeM3,
                weightT: d.weightT,
                distanceKm: d.distanceKm,
                loadKind: d.loadKind,
                priceLabel: d.priceLabel,
                onTap: () => context.push(
                  guest
                      ? '/guest-post-truck/${d.truck.guid}'
                      : '/post-truck/${d.truck.guid}',
                ),
              );
            },
          ),
        );
      },
    );
  }
}
