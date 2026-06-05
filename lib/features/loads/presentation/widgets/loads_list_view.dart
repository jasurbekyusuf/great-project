import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_controller.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_display_providers.dart';
import 'package:loadme_mobile/features/loads/presentation/widgets/load_figma_card.dart';
import 'package:loadme_mobile/shared/design_system/ds_empty_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_error_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_loader.dart';

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
        if (items.isEmpty) return DsEmptyState(title: 'common.notFound'.tr(ref));
        return RefreshIndicator(
          onRefresh: () => ref.read(loadsControllerProvider.notifier).refresh(),
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(s.lg, 0, s.lg, s.lg),
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(height: s.sm),
            itemBuilder: (_, i) {
              final d = items[i];
              return LoadFigmaCard(
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
                onTap: () => context.push(
                  guest ? '/guest-load/${d.load.guid}' : '/loads/${d.load.guid}',
                ),
              );
            },
          ),
        );
      },
    );
  }
}
