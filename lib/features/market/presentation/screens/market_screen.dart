import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_controller.dart';
import 'package:loadme_mobile/features/loads/presentation/widgets/loads_filters_block.dart';
import 'package:loadme_mobile/features/loads/presentation/widgets/loads_list_view.dart';
import 'package:loadme_mobile/features/trucks/presentation/controllers/trucks_controller.dart';
import 'package:loadme_mobile/features/trucks/presentation/widgets/trucks_list_view.dart';
import 'package:loadme_mobile/shared/widgets/app_bottom_nav.dart';
import 'package:loadme_mobile/shared/widgets/loadme_brand_mark.dart';
import 'package:loadme_mobile/shared/widgets/mobile_auth_required_sheet.dart';
import 'package:loadme_mobile/shared/widgets/mobile_segmented_tab.dart';
import 'package:loadme_mobile/shared/widgets/select_location_drawer.dart';

enum MarketTab { loads, trucks }

/// Unified market browsing screen. Header / filters stay put — only the
/// list cross-fades between `loads` and `trucks` tabs.
///
/// Routes `/loads` and `/trucks` both render this same widget. The tab
/// segmented control swaps content in-place via `setState` (no navigation),
/// avoiding the full-screen rebuild that the previous route-per-tab design
/// produced.
class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({
    super.key,
    this.initialTab = MarketTab.loads,
    this.guest = false,
  });

  final MarketTab initialTab;
  final bool guest;

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  late MarketTab _tab = widget.initialTab;
  bool _filtersExpanded = true;
  LocationItem? _origin;
  LocationItem? _destination;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.background,
      bottomNavigationBar: widget.guest
          ? AppBottomNav(currentIndex: 0, guest: widget.guest)
          : null,
      body: Column(
        children: [
          _MarketHeader(
            tabIndex: _tab.index,
            tabLabels: ['loads.title'.tr(ref), 'trucks.title'.tr(ref)],
            guest: widget.guest,
            onTabChanged: (i) => setState(() => _tab = MarketTab.values[i]),
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
                  onSearch: _runSearch,
                  onFilter: () => context.push('/loads/filters'),
                ),
                _FilterRow(
                  guest: widget.guest,
                  countLabel: _tab == MarketTab.loads
                      ? '${'loads.allCount'.tr(ref)}: 14370'
                      : '${'trucks.title'.tr(ref)}: 8',
                  filtersExpanded: _filtersExpanded,
                  onToggleFilters: () =>
                      setState(() => _filtersExpanded = !_filtersExpanded),
                  onRefresh: _refreshActive,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: child,
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_tab),
                      child: _tab == MarketTab.loads
                          ? LoadsListView(guest: widget.guest)
                          : TrucksListView(guest: widget.guest),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _runSearch() {
    if (_tab == MarketTab.loads) {
      final q = [
        _origin?.title ?? '',
        _destination?.title ?? '',
      ].where((e) => e.isNotEmpty).join(' ');
      ref.read(loadsControllerProvider.notifier).applyQuery(q);
    } else {
      ref.invalidate(trucksControllerProvider);
    }
  }

  void _refreshActive() {
    if (_tab == MarketTab.loads) {
      ref.read(loadsControllerProvider.notifier).refresh();
    } else {
      ref.invalidate(trucksControllerProvider);
    }
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _MarketHeader extends StatelessWidget {
  const _MarketHeader({
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
                        decoration: BoxDecoration(
                          color: c.surfaceMuted,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          color: c.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Web LoadsV2 uses the default CustomTab look: white pill on
              // a light gray track (`tabs.truck = gray.200`, `tabs.active =
              // white`). The blue/primaryFilled variant doesn't exist on web.
              MobileSegmentedTab(
                items: tabLabels,
                selectedIndex: tabIndex,
                onChanged: onTabChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter count + show/hide toggle row
// ---------------------------------------------------------------------------

class _FilterRow extends ConsumerWidget {
  const _FilterRow({
    required this.guest,
    required this.countLabel,
    required this.filtersExpanded,
    required this.onToggleFilters,
    required this.onRefresh,
  });

  final bool guest;
  final String countLabel;
  final bool filtersExpanded;
  final VoidCallback onToggleFilters;
  final VoidCallback onRefresh;

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
              Text(
                countLabel,
                style: t.bodyMedium.copyWith(
                  color: c.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                    filtersExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
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
            onTap: onRefresh,
            child: Icon(Icons.refresh_rounded, size: 20, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}
