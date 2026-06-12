import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_controller.dart';
import 'package:loadme_mobile/features/loads/presentation/widgets/loads_list_view.dart';
import 'package:loadme_mobile/features/trucks/presentation/controllers/trucks_controller.dart';
import 'package:loadme_mobile/features/trucks/presentation/widgets/trucks_list_view.dart';
import 'package:loadme_mobile/shared/widgets/floating_market_nav.dart';
import 'package:loadme_mobile/shared/widgets/mobile_auth_required_sheet.dart';
import 'package:loadme_mobile/shared/widgets/select_location_drawer.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum MarketTab { loads, trucks }

/// Search page — pixel port of Figma frame 6435:34114 (Dev Mode values).
///
/// Vertical rhythm (relative to the status-bar bottom), from the Figma frame
/// where the 44px status bar is baked into the 375×218 blue header:
///   • tabs           y=56  → +12,  h=40
///   • search (Input) y=112 → +68,  h=62
///   • content sheet  y=190 → +146  (#F3F4F7, top radius 20, overlaps blue)
///   • blue ends      y=218 → +174
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
  LocationItem? _origin;
  LocationItem? _destination;

  // Figma offsets (status bar already excluded — we add topInset at runtime).
  static const _tabTop = 12.0;
  static const _tabHeight = 40.0;
  static const _searchTop = 68.0;
  static const _searchHeight = 62.0;
  static const _sheetTop = 146.0;
  static const _blueHeight = 174.0;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: FigmaPalette.pageBg,
      // Guest mode hosts the frosted nav directly; let content scroll behind.
      extendBody: widget.guest,
      bottomNavigationBar: widget.guest
          ? FloatingMarketNav(
              activeIndex: 0,
              onTap: (i) {
                if (i == 0) return;
                showMobileAuthRequiredSheet(context);
              },
            )
          : null,
      body: Stack(
        children: [
          // ── Blue header illustration (exact Figma export) ──────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topInset + _blueHeight,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                // `fill` (not cover) so the full gradient always shows — cover
                // crops the bright top-left on devices with a taller status bar.
                image: DecorationImage(
                  image: AssetImage('assets/images/market_header_bg.png'),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),

          // ── Content sheet (#F3F4F7, rounded top, overlaps blue) ────
          Column(
            children: [
              SizedBox(height: topInset + _sheetTop),
              Expanded(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: FigmaPalette.sheetBg,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: _CountFilterRow(
                          countLabel: _tab == MarketTab.loads
                              ? '${'loads.allCount'.tr(ref)}: 14 370'
                              : '${'trucks.title'.tr(ref)}: 8',
                          onFilter: _openFilters,
                        ),
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, anim) =>
                              FadeTransition(opacity: anim, child: child),
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
              ),
            ],
          ),

          // ── Pill tabs (transparent, white-outlined) ────────────────
          Positioned(
            top: topInset + _tabTop,
            left: 16,
            right: 16,
            height: _tabHeight,
            child: _PillTabs(
              labels: ['loads.title'.tr(ref), 'trucks.title'.tr(ref)],
              selectedIndex: _tab.index,
              onChanged: (i) => setState(() => _tab = MarketTab.values[i]),
            ),
          ),

          // ── Search card ────────────────────────────────────────────
          Positioned(
            top: topInset + _searchTop,
            left: 16,
            right: 16,
            height: _searchHeight,
            child: _CombinedSearchBar(
              origin: _origin,
              destination: _destination,
              onTapSearch: _openLocationSheet,
              onTapAll: _openFilters,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLocationSheet() async {
    if (widget.guest) {
      await showMobileAuthRequiredSheet(context);
      return;
    }
    final picked = await showSelectLocationDrawer(
      context: context,
      title: 'loads.originPlace'.tr(ref),
      currentId: _origin?.id,
    );
    if (picked != null) {
      setState(() => _origin = picked);
      _runSearch();
    }
  }

  void _openFilters() {
    if (widget.guest) {
      showMobileAuthRequiredSheet(context);
      return;
    }
    context.push('/loads/filters');
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
}

// ---------------------------------------------------------------------------
// Pill tabs — Figma `Content` (167.5×40): transparent fill, white border,
// white label; active gets a solid white border + white 8px dot + weight 500.
// ---------------------------------------------------------------------------

class _PillTabs extends StatelessWidget {
  const _PillTabs({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      // Stretch so each tab fills the full 40px height (otherwise the tabs
      // shrink to their text height and look short / overly rounded).
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(labels.length, (i) {
        final active = i == selectedIndex;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: DecoratedBox(
                // Dev Mode (Frame 2087329688 > Content):
                //   bg rgba(255,255,255,0.01); radius 12;
                //   active   border 1px #FFFFFF
                //   inactive border 1px rgba(255,255,255,0.08)
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.01),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (active) ...[
                        // Rectangle 11774 — 8×8 white dot.
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          labels[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight:
                                active ? FontWeight.w500 : FontWeight.w400,
                            color: active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.96),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Combined search bar — Figma `Input` (343×62, r16, pad 10/14, gap 10).
// ---------------------------------------------------------------------------

class _CombinedSearchBar extends StatelessWidget {
  const _CombinedSearchBar({
    required this.origin,
    required this.destination,
    required this.onTapSearch,
    required this.onTapAll,
  });

  final LocationItem? origin;
  final LocationItem? destination;
  final VoidCallback onTapSearch;
  final VoidCallback onTapAll;

  @override
  Widget build(BuildContext context) {
    final routeText = (origin == null && destination == null)
        ? 'Qayerdan → Qayerga'
        : '${origin?.title ?? '...'} → ${destination?.title ?? '...'}';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D101828), // rgba(16,24,40,0.05)
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Blue rounded square (36×36 r14) with search icon.
            GestureDetector(
              onTap: onTapSearch,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: FigmaPalette.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(LucideIcons.search, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            // "Qidiruv" + route sub-text.
            Expanded(
              child: GestureDetector(
                onTap: onTapSearch,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Qidiruv',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.25,
                        fontWeight: FontWeight.w400,
                        color: FigmaPalette.ink,
                      ),
                    ),
                    Text(
                      routeText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                        color: FigmaPalette.label,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(width: 1, height: 36, color: FigmaPalette.divider),
            const SizedBox(width: 10),
            // "Hamma" — truck icon + label.
            GestureDetector(
              onTap: onTapAll,
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.truck, color: FigmaPalette.ink, size: 20),
                  const SizedBox(height: 2),
                  const Text(
                    'Hamma',
                    style: TextStyle(
                      fontSize: 13,
                      height: 18 / 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF98A2B3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Count + filter row — Figma `Frame 2087329681`.
//   left  : "Barcha yuklar: X"  #0B1020 14/500
//   right : white pill button (shadow, r8) with blue filter icon + "Filtr"
// ---------------------------------------------------------------------------

class _CountFilterRow extends StatelessWidget {
  const _CountFilterRow({required this.countLabel, required this.onFilter});

  final String countLabel;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            countLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w500,
              color: FigmaPalette.countLabel,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onFilter,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x05000000), // rgba(0,0,0,0.02)
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.slidersHorizontal, size: 18, color: FigmaPalette.primary),
                SizedBox(width: 6),
                Text(
                  'Filtr',
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w500,
                    color: FigmaPalette.primary,
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
