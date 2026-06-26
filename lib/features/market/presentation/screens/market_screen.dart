import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/features/auth/presentation/providers/current_user_provider.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_controller.dart';
import 'package:loadme_mobile/features/loads/presentation/widgets/loads_list_view.dart';
import 'package:loadme_mobile/features/locations/presentation/providers/location_status_provider.dart';
import 'package:loadme_mobile/features/market/presentation/widgets/loads_search_sheet.dart';
import 'package:loadme_mobile/features/trucks/presentation/controllers/trucks_controller.dart';
import 'package:loadme_mobile/features/trucks/presentation/widgets/trucks_list_view.dart';
import 'package:loadme_mobile/shared/widgets/floating_market_nav.dart';
import 'package:loadme_mobile/shared/widgets/mobile_auth_required_sheet.dart';
import 'package:loadme_mobile/shared/widgets/select_location_drawer.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum MarketTab { loads, trucks }

/// Formats the marketplace total with space-grouped thousands ("14370" →
/// "14 370"), showing a dash placeholder until the real count arrives (or if
/// the count request fails).
String _formatCount(int? value) {
  if (value == null) return '—';
  final digits = value.abs().toString();
  final buf = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
    buf.write(digits[i]);
  }
  return buf.toString();
}

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
  String? _truckType;

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

    // Tab order is role-aware. Carriers (drivers) — and unauthenticated guests,
    // whose role is unknown — hunt for cargo, so "Yuklar" stays on the left
    // (unchanged). Cargo owners (shipper / broker) hunt for trucks, so "Yuk
    // mashinalari" takes the left-most slot. `_tab` remains the single source
    // of truth — only the visual order of the two pills flips.
    final loadsFirst =
        widget.guest || ref.watch(currentUserRoleSyncProvider) == 'carrier';
    final tabOrder = loadsFirst
        ? const [MarketTab.loads, MarketTab.trucks]
        : const [MarketTab.trucks, MarketTab.loads];

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
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      const _LocationBanner(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: _CountFilterRow(
                          countLabel: _tab == MarketTab.loads
                              ? _loadsCountLabel()
                              : '${'trucks.title'.tr(ref)}: ${_formatCount(ref.watch(trucksCountProvider).valueOrNull)}',
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
                                ? LoadsListView(
                                    guest: widget.guest,
                                    nearbyTitle: _origin?.title,
                                    nearbyFilters: _origin == null
                                        ? null
                                        : {
                                            'pickup_${_origin!.filterKey}':
                                                _origin!.id,
                                          },
                                  )
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
              labels: [
                for (final t in tabOrder)
                  (t == MarketTab.loads ? 'loads.title' : 'trucks.title')
                      .tr(ref),
              ],
              selectedIndex: tabOrder.indexOf(_tab),
              onChanged: (i) => setState(() => _tab = tabOrder[i]),
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
              onTapSearch: _openSearchSheet,
              onTapAll: _openFilters,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSearchSheet() async {
    // Search is a browse aid — like the Filtrlar screen, guests may use it
    // without the login prompt. Both the location lookup and the public load
    // feed work anonymously.
    final result = await showLoadsSearchSheet(
      context: context,
      origin: _origin,
      destination: _destination,
      truckType: _truckType,
    );
    if (result != null) {
      setState(() {
        _origin = result.origin;
        _destination = result.destination;
        _truckType = result.truckType;
      });
      _runSearch();
    }
  }

  void _openFilters() {
    // Filters are a browse aid — guests reach them through the dedicated
    // `/guest-filters` route instead of being gated behind the login prompt.
    context.push(widget.guest ? '/guest-filters' : '/loads/filters');
  }

  void _runSearch() {
    if (_tab == MarketTab.loads) {
      // Apply the picked places as a *server* filter on `/loads/available/`
      // (the same path the Filtrlar screen uses) so the whole feed narrows —
      // not just the rows already paged in. An empty pick clears the filter.
      ref
          .read(loadsControllerProvider.notifier)
          .applyLocationFilter(_loadsFilters());
    } else {
      ref.invalidate(trucksControllerProvider);
    }
  }

  /// The active loads search as a server filter map (`pickup_*` / `delivery_*`
  /// → place id), empty when no Qidiruv place is set. Shared by the feed
  /// narrowing, the count header, and the empty-state nearby fallback so all
  /// three stay coherent.
  Map<String, String> _loadsFilters() {
    final filters = <String, String>{};
    final origin = _origin;
    final destination = _destination;
    if (origin != null) filters['pickup_${origin.filterKey}'] = origin.id;
    if (destination != null) {
      filters['delivery_${destination.filterKey}'] = destination.id;
    }
    return filters;
  }

  /// "Topildi: N" once a Qidiruv narrows the feed, otherwise the whole-feed
  /// "Barcha yuklar: N" — the count is the real backend total for the active
  /// filter (keyed by its canonical string so equal filters share one fetch).
  String _loadsCountLabel() {
    final filters = _loadsFilters();
    final count = _formatCount(
      ref.watch(loadsCountProvider(loadsFilterKey(filters))).valueOrNull,
    );
    final label =
        (filters.isEmpty ? 'loads.allCount' : 'loads.foundCount').tr(ref);
    return '$label: $count';
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
                child: const Icon(LucideIcons.search,
                    color: Colors.white, size: 20),
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
                  const Icon(LucideIcons.truck,
                      color: FigmaPalette.ink, size: 20),
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
                // Figma uses a funnel (filter) glyph, not sliders.
                Icon(LucideIcons.filter,
                    size: 18, color: FigmaPalette.primary),
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

// ---------------------------------------------------------------------------
// Location-off banner — shown above the marketplace list while the device
// can't give a position (location service off, or permission missing). Tapping
// runs the best-effort `enableLocation` flow (permission prompt → settings).
//
// NOTE: the Figma we were given only includes the empty-search frame
// (6435:39539); no dedicated "location off" frame was shared, so this banner's
// styling is a best-effort interpretation pending the real design node.
// ---------------------------------------------------------------------------

class _LocationBanner extends ConsumerWidget {
  const _LocationBanner();

  static const _orange = Color(0xFFF2994A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Defaults to `true` (banner hidden) until the check resolves and on any
    // geolocator hiccup, so a platform error never nags with a false warning.
    final enabled = ref.watch(locationEnabledProvider).valueOrNull ?? true;
    if (enabled) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: const Color(0xFFFFF6ED),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => enableLocation(ref),
          borderRadius: BorderRadius.circular(12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _orange),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE7D2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.mapPin,
                      size: 20,
                      color: _orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Joylashuvni yoqing',
                          style: TextStyle(
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight: FontWeight.w600,
                            color: FigmaPalette.inkStrong,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Yaqin atrofdagi yuklarni topish uchun '
                          'joylashuvga ruxsat bering.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 16 / 12,
                            fontWeight: FontWeight.w400,
                            color: FigmaPalette.gray700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 20,
                    color: FigmaPalette.gray700,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
