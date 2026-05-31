import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/loads/domain/entities/load_entity.dart';
import 'package:loadme_mobile/features/loads/presentation/widgets/load_figma_card.dart';
import 'package:loadme_mobile/features/loads/presentation/widgets/loads_filters_block.dart';
import 'package:loadme_mobile/features/trucks/presentation/controllers/trucks_controller.dart';
import 'package:loadme_mobile/features/trucks/presentation/controllers/trucks_display_providers.dart';
import 'package:loadme_mobile/shared/widgets/select_location_drawer.dart';
import 'package:loadme_mobile/shared/design_system/ds_empty_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_error_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_loader.dart';
import 'package:loadme_mobile/shared/widgets/app_bottom_nav.dart';
import 'package:loadme_mobile/shared/widgets/loadme_brand_mark.dart';
import 'package:loadme_mobile/shared/widgets/mobile_auth_required_sheet.dart';
import 'package:loadme_mobile/shared/widgets/mobile_segmented_tab.dart';

// Mirrors the Loads search screen but with the "Yuk mashinalari" tab active.
// Re-uses [LoadFigmaCard] so the card design is identical to Loads list.
class TrucksScreen extends ConsumerStatefulWidget {
  const TrucksScreen({super.key, this.guest = false});
  final bool guest;

  @override
  ConsumerState<TrucksScreen> createState() => _TrucksScreenState();
}

class _TrucksScreenState extends ConsumerState<TrucksScreen> {
  int _tabIndex = 1;
  bool _filtersExpanded = true;
  LocationItem? _origin;
  LocationItem? _destination;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trucksDisplayProvider);
    final c = context.colors;
    final s = context.space;

    return Scaffold(
      backgroundColor: c.background,
      bottomNavigationBar: AppBottomNav(currentIndex: 0, guest: widget.guest),
      body: Column(
        children: [
          _TrucksHeader(
            tabIndex: _tabIndex,
            tabLabels: ['loads.title'.tr(ref), 'trucks.title'.tr(ref)],
            guest: widget.guest,
            onTabChanged: (i) {
              setState(() => _tabIndex = i);
              if (i == 0) context.go(widget.guest ? '/guest' : '/loads');
            },
          ),
          Expanded(
            child: Column(
              children: [
                LoadsFiltersBlock(
                  expanded: _filtersExpanded,
                  origin: _origin,
                  destination: _destination,
                  onOriginChanged: (v) => setState(() => _origin = v),
                  onDestinationChanged: (v) => setState(() => _destination = v),
                  onSearch: () => ref.invalidate(trucksControllerProvider),
                  onFilter: () => context.push('/loads/filters'),
                ),
                _FilterRow(
                  guest: widget.guest,
                  countLabel: '${'trucks.title'.tr(ref)}: 8',
                  filtersExpanded: _filtersExpanded,
                  onToggleFilters: () => setState(() => _filtersExpanded = !_filtersExpanded),
                ),
                Expanded(
                  child: state.when(
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
                            // Reuse LoadFigmaCard — adapt TruckEntity into a
                            // synthetic LoadEntity for shared rendering.
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
                                widget.guest
                                    ? '/guest-post-truck/${d.truck.guid}'
                                    : '/post-truck/${d.truck.guid}',
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrucksHeader extends StatelessWidget {
  const _TrucksHeader({
    required this.tabIndex,
    required this.tabLabels,
    required this.onTabChanged,
    required this.guest,
  });

  final int tabIndex;
  final List<String> tabLabels;
  final ValueChanged<int> onTabChanged;
  final bool guest;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.space;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(s.radiusXl),
          bottomRight: Radius.circular(s.radiusXl),
        ),
        border: Border(bottom: BorderSide(color: c.borderSubtle)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const LoadMeBrandMark(size: 32),
                  const Spacer(),
                  Builder(
                    builder: (ctx) => InkResponse(
                      onTap: () {
                        if (guest) return;
                        ctx.push('/notifications');
                      },
                      radius: 22,
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: c.surfaceMuted, shape: BoxShape.circle),
                        child: Icon(Icons.notifications_none_rounded, color: c.textPrimary, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MobileSegmentedTab(
                items: tabLabels,
                selectedIndex: tabIndex,
                onChanged: onTabChanged,
                variant: MobileSegmentedTabVariant.primaryFilled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends ConsumerWidget {
  const _FilterRow({
    required this.guest,
    required this.countLabel,
    required this.filtersExpanded,
    required this.onToggleFilters,
  });
  final bool guest;
  final String countLabel;
  final bool filtersExpanded;
  final VoidCallback onToggleFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.types;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              if (guest) {
                showMobileAuthRequiredSheet(context);
              } else {
                context.push('/loads/filters');
              }
            },
            child: Row(children: [
              Icon(Icons.tune_rounded, size: 18, color: c.primary),
              const SizedBox(width: 6),
              Text(countLabel, style: t.bodyMedium.copyWith(color: c.primary, fontWeight: FontWeight.w600)),
            ]),
          ),
          const Spacer(),
          InkWell(
            onTap: onToggleFilters,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (filtersExpanded ? 'common.hide' : 'common.show').tr(ref),
                    style: t.caption.copyWith(color: c.textPrimary),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    filtersExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: c.textPrimary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkResponse(
            radius: 20,
            onTap: () => ref.invalidate(trucksControllerProvider),
            child: Icon(Icons.refresh_rounded, size: 20, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}
