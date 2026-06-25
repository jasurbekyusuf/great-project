import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/features/auth/presentation/providers/current_user_provider.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_controller.dart';
import 'package:loadme_mobile/features/loads/presentation/widgets/loads_list_view.dart';
import 'package:loadme_mobile/features/locations/domain/entities/location_entity.dart';
import 'package:loadme_mobile/features/locations/presentation/providers/locations_providers.dart';
import 'package:loadme_mobile/features/trucks/presentation/controllers/trucks_controller.dart';
import 'package:loadme_mobile/features/trucks/presentation/widgets/trucks_list_view.dart';
import 'package:loadme_mobile/shared/design_system/ds_truck_type_drawer.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: _CountFilterRow(
                          countLabel: _tab == MarketTab.loads
                              ? '${'loads.allCount'.tr(ref)}: ${_formatCount(ref.watch(loadsCountProvider).valueOrNull)}'
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
              labels: [
                for (final t in tabOrder)
                  (t == MarketTab.loads ? 'loads.title' : 'trucks.title').tr(ref),
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
      final filters = <String, String>{};
      final origin = _origin;
      final destination = _destination;
      if (origin != null) filters['pickup_${origin.filterKey}'] = origin.id;
      if (destination != null) {
        filters['delivery_${destination.filterKey}'] = destination.id;
      }
      ref.read(loadsControllerProvider.notifier).applyLocationFilter(filters);
    } else {
      ref.invalidate(trucksControllerProvider);
    }
  }
}

// ---------------------------------------------------------------------------
// "Yuklarni qidirish" — search sheet from the market search bar
// (Figma 6435:34680 / 36792): Qayerdan + Qayerga + Transport turi + Tayyor.
// The location fields reuse the searchable location drawer for autocomplete.
// ---------------------------------------------------------------------------

class LoadsSearchResult {
  const LoadsSearchResult({this.origin, this.destination, this.truckType});
  final LocationItem? origin;
  final LocationItem? destination;
  final String? truckType;
}

Future<LoadsSearchResult?> showLoadsSearchSheet({
  required BuildContext context,
  LocationItem? origin,
  LocationItem? destination,
  String? truckType,
}) {
  // Figma 6435:34680 — the panel drops straight down from the collapsed search
  // bar (just beneath the pill tabs), it does NOT rise from the bottom. Anchor
  // its top to the search bar's offset (status-bar inset + _searchTop) and dim
  // the rest of the screen behind it.
  final topInset = MediaQuery.of(context).padding.top;
  const searchBarTop = 68.0; // mirrors _MarketScreenState._searchTop
  return showGeneralDialog<LoadsSearchResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: topInset + searchBarTop),
        // showGeneralDialog (unlike a bottom sheet) provides no Material
        // ancestor, so the inner TextFields/InkWells need one. Transparent so
        // the card paints its own #F6F7F9 fill.
        child: Material(
          type: MaterialType.transparency,
          child: _LoadsSearchSheet(
            origin: origin,
            destination: destination,
            truckType: truckType,
          ),
        ),
      ),
    ),
    transitionBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

// Every concrete truck-type label (deduped, order-preserving) flattened from
// the shared taxonomy — the inline transport dropdown filters against this.
final List<String> _kAllTruckTypes = <String>{
  for (final g in kTruckTypeGroups) ...g.items,
}.toList();

class _LoadsSearchSheet extends ConsumerStatefulWidget {
  const _LoadsSearchSheet({this.origin, this.destination, this.truckType});
  final LocationItem? origin;
  final LocationItem? destination;
  final String? truckType;

  @override
  ConsumerState<_LoadsSearchSheet> createState() => _LoadsSearchSheetState();
}

class _LoadsSearchSheetState extends ConsumerState<_LoadsSearchSheet> {
  // Which location field carries the blue "focused" outline (Figma 6435:34680).
  // 0 = Qayerdan (origin), 1 = Qayerga (destination).
  int _active = 0;

  LocationItem? _origin;
  LocationItem? _destination;
  late final List<String> _selectedTrucks =
      (widget.truckType == null || widget.truckType!.isEmpty)
          ? <String>[]
          : widget.truckType!.split(', ');

  final _originController = TextEditingController();
  final _destController = TextEditingController();
  final _truckController = TextEditingController();
  final _originFocus = FocusNode();
  final _destFocus = FocusNode();
  final _truckFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _origin = widget.origin;
    _destination = widget.destination;
    if (_origin != null) _originController.text = _origin!.title;
    if (_destination != null) _destController.text = _destination!.title;
    if (_selectedTrucks.isNotEmpty) {
      _truckController.text = _selectedTrucks.join(', ');
    }
    _originFocus.addListener(_onFocusChange);
    _destFocus.addListener(_onFocusChange);
    _truckFocus.addListener(_onTruckFocusChange);
  }

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    _truckController.dispose();
    _originFocus.dispose();
    _destFocus.dispose();
    _truckFocus.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_originFocus.hasFocus && _active != 0) {
      setState(() => _active = 0);
    } else if (_destFocus.hasFocus && _active != 1) {
      setState(() => _active = 1);
    } else {
      // A field lost focus (keyboard dismissed) — refresh so the dropdown hides.
      setState(() {});
    }
  }

  void _onTruckFocusChange() {
    // Focusing/blurring the transport field swaps its chevron up/down and
    // shows or hides the inline transport dropdown.
    setState(() {});
  }

  FocusNode get _activeFocus => _active == 0 ? _originFocus : _destFocus;
  TextEditingController get _activeController =>
      _active == 0 ? _originController : _destController;

  // The inline suggestions list opens only while the focused field has a query
  // (the empty-focused state shows Transport + Tayyor instead — Figma 34680).
  bool get _dropdownOpen =>
      _activeFocus.hasFocus && _activeController.text.trim().isNotEmpty;

  void _onChanged(bool origin, String _) {
    // Free typing detaches any previously chosen location for that field.
    setState(() {
      if (origin) {
        _origin = null;
      } else {
        _destination = null;
      }
    });
  }

  void _select(LocationItem loc) {
    setState(() {
      if (_active == 0) {
        _origin = loc;
        _originController.text = loc.title;
      } else {
        _destination = loc;
        _destController.text = loc.title;
      }
    });
    _activeFocus.unfocus();
  }

  // "Har qanday joydan / joyga" — clears the active field's constraint.
  void _selectAny() {
    setState(() {
      if (_active == 0) {
        _origin = null;
        _originController.clear();
      } else {
        _destination = null;
        _destController.clear();
      }
    });
    _activeFocus.unfocus();
  }

  void _clear(bool origin) {
    setState(() {
      if (origin) {
        _origin = null;
        _originController.clear();
      } else {
        _destination = null;
        _destController.clear();
      }
    });
  }

  // The transport dropdown opens whenever its field is focused (Figma 34680):
  // an empty field lists the popular quick-picks, typing filters the full
  // taxonomy. Single-select — picking one collapses the list onto the field.
  bool get _truckDropdownOpen => _truckFocus.hasFocus;

  List<String> get _truckSuggestions {
    final q = _truckController.text.trim().toLowerCase();
    if (q.isEmpty) return kPopularTruckTypes;
    return _kAllTruckTypes.where((t) => t.toLowerCase().contains(q)).toList();
  }

  void _onTruckChanged(String _) {
    // Free typing detaches any previously chosen type.
    setState(() => _selectedTrucks.clear());
  }

  void _selectTruck(String t) {
    setState(() {
      _selectedTrucks
        ..clear()
        ..add(t);
      _truckController.text = t;
    });
    _truckFocus.unfocus();
  }

  // "Har qanday transport" — clears any chosen type.
  void _selectAnyTruck() {
    setState(() {
      _selectedTrucks.clear();
      _truckController.clear();
    });
    _truckFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final originField = _LocationField(
      active: _active == 0,
      // Figma 6435:34680 — each field is its own fully-rounded r12 white pill.
      borderRadius: BorderRadius.circular(12),
      marker: _marker(filled: true, active: _active == 0),
      hint: 'Qayerdan',
      controller: _originController,
      focusNode: _originFocus,
      onChanged: (v) => _onChanged(true, v),
      onClear: () => _clear(true),
    );
    final destField = _LocationField(
      active: _active == 1,
      borderRadius: BorderRadius.circular(12),
      marker: _marker(filled: false, active: _active == 1),
      hint: 'Qayerga',
      controller: _destController,
      focusNode: _destFocus,
      onChanged: (v) => _onChanged(false, v),
      onClear: () => _clear(false),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        // Floating rounded-16 card on the #F6F7F9 page colour, 16 inner padding.
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: FigmaPalette.pageBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Yuklarni qidirish',
                        style: TextStyle(
                          fontSize: 16,
                          height: 24 / 16,
                          fontWeight: FontWeight.w600,
                          color: FigmaPalette.ink,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      behavior: HitTestBehavior.opaque,
                      child: const Icon(LucideIcons.x,
                          size: 24, color: FigmaPalette.ink),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Qayerdan + Qayerga are two SEPARATE white r12 fields divided
                // by an 8px gap (Figma 6435:34680): each paints its own white
                // fill and the focused one a fully-rounded 1.5px blue outline.
                originField,
                const SizedBox(height: 8),
                destField,
                // The matching suggestions open beneath the whole pair (36792).
                if (_dropdownOpen) ...[
                  const SizedBox(height: 8),
                  // Flexible so the list shrinks (and scrolls internally) to fit
                  // the space left above the keyboard instead of overflowing.
                  Flexible(child: _dropdown()),
                ],
                if (!_dropdownOpen) ...[
                  const SizedBox(height: 12),
                  // Transport type — an inline typeable field (Figma 34680):
                  // blue r12 outline + chevron-up while focused, with its own
                  // dropdown below; otherwise the Tayyor button sits here.
                  _TransportField(
                    active: _truckFocus.hasFocus,
                    controller: _truckController,
                    focusNode: _truckFocus,
                    onChanged: _onTruckChanged,
                  ),
                  if (_truckDropdownOpen) ...[
                    const SizedBox(height: 8),
                    Flexible(child: _truckDropdown()),
                  ] else ...[
                    const SizedBox(height: 12),
                    DsButton(
                      label: 'Tayyor',
                      onPressed: () => Navigator.pop(
                        context,
                        LoadsSearchResult(
                          origin: _origin,
                          destination: _destination,
                          truckType: _selectedTrucks.isEmpty
                              ? null
                              : _selectedTrucks.join(', '),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 24×24 location marker. Origin → filled dot, destination → hollow ring.
  // The tile stays #F2F4F7 in every state (Figma 2087329694); only the glyph
  // turns blue when its field is focused — there is no blue tile fill.
  Widget _marker({required bool filled, required bool active}) {
    final color = active ? FigmaPalette.primary : FigmaPalette.label;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: FigmaPalette.chipBg,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: filled ? color : null,
          shape: BoxShape.circle,
          border: filled ? null : Border.all(color: color, width: 1.5),
        ),
      ),
    );
  }

  // Inline suggestions list (Figma 6435:36792 Frame 2087329695): rounded-16
  // white card with a soft drop-shadow; a leading "Har qanday joy…" row, then
  // the live `/locations/search/` matches split by hairline dividers. The query
  // is debounced (300ms) inside `locationSearchProvider`.
  Widget _dropdown() {
    final anyLabel = _active == 0 ? 'Har qanday joydan' : 'Har qanday joyga';
    final query = _activeController.text.trim();
    final results = ref.watch(locationSearchProvider(query));
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: FigmaPalette.cardShadow,
            offset: Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        children: [
          InkWell(
            onTap: _selectAny,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(LucideIcons.mapPin,
                      size: 20, color: FigmaPalette.inkStrong),
                  const SizedBox(width: 12),
                  Text(
                    anyLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w400,
                      color: FigmaPalette.inkStrong,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...results.when(
            data: (items) {
              if (items.isEmpty) {
                return [
                  const Divider(
                      height: 1, thickness: 1, color: FigmaPalette.divider),
                  _statusTile('Hech narsa topilmadi'),
                ];
              }
              return [
                for (final loc in items) ...[
                  const Divider(
                      height: 1, thickness: 1, color: FigmaPalette.divider),
                  _cityTile(loc),
                ],
              ];
            },
            loading: () => [
              const Divider(
                  height: 1, thickness: 1, color: FigmaPalette.divider),
              _loadingTile(),
            ],
            error: (_, __) => [
              const Divider(
                  height: 1, thickness: 1, color: FigmaPalette.divider),
              _statusTile('Qidirishda xatolik. Qayta urinib koʻring'),
            ],
          ),
        ],
      ),
    );
  }

  // One live location match — pin glyph + name + a muted "region, country"
  // subtitle (Figma 6435:36792). Tapping converts the entity into the
  // [LocationItem] the rest of the search flow expects.
  Widget _cityTile(LocationEntity loc) {
    return InkWell(
      onTap: () => _select(LocationItem.fromEntity(loc)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            const Icon(LucideIcons.mapPin, size: 20, color: FigmaPalette.label),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    loc.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w400,
                      color: FigmaPalette.inkStrong,
                    ),
                  ),
                  if (loc.subtitle != null)
                    Text(
                      loc.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w400,
                        color: FigmaPalette.label,
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

  // Centered spinner shown while the debounced search request is in flight.
  Widget _loadingTile() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  // Muted single-line message row for the empty / error states.
  Widget _statusTile(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 14,
          height: 20 / 14,
          fontWeight: FontWeight.w400,
          color: FigmaPalette.label,
        ),
      ),
    );
  }

  // Inline transport-type list (Figma 6435:34680): the same rounded-16 white
  // card as the location dropdown — a leading "Har qanday transport" row, then
  // the popular (or filtered) types split by hairline dividers.
  Widget _truckDropdown() {
    final items = _truckSuggestions;
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: FigmaPalette.cardShadow,
            offset: Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        children: [
          InkWell(
            onTap: _selectAnyTruck,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(LucideIcons.truck,
                      size: 20, color: FigmaPalette.inkStrong),
                  SizedBox(width: 12),
                  Text(
                    'Har qanday transport',
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w400,
                      color: FigmaPalette.inkStrong,
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final t in items) ...[
            const Divider(height: 1, thickness: 1, color: FigmaPalette.divider),
            InkWell(
              onTap: () => _selectTruck(t),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                child: Text(
                  t,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w400,
                    color: FigmaPalette.inkStrong,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One location field of the search sheet — 48px tall, white, rounded-12, with
/// a leading marker, an inline [TextField] for the query, and a clear-X once it
/// holds text. The focused field paints a 1.5px blue outline (Figma 6435:36792).
class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.active,
    required this.borderRadius,
    required this.marker,
    required this.hint,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final bool active;
  final BorderRadius borderRadius;
  final Widget marker;
  final String hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        // Each field paints its own white fill and fully-rounded corners. The
        // border is ALWAYS 1.5px (transparent when idle) so the marker + text
        // never shift inward by the border width when the field gains focus —
        // keeping both fields perfectly level (Figma 6435:34680).
        color: Colors.white,
        borderRadius: borderRadius,
        border: Border.all(
          color: active ? FigmaPalette.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          marker,
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              cursorColor: FigmaPalette.primary,
              cursorWidth: 1.5,
              style: const TextStyle(
                fontSize: 16,
                height: 24 / 16,
                // Even leading splits the extra line height equally above and
                // below the glyphs so the text sits on the field's true vertical
                // centre (level with the leading icon), not riding high.
                leadingDistribution: TextLeadingDistribution.even,
                fontWeight: FontWeight.w400,
                color: FigmaPalette.countLabel,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                // Clear the app theme's global inputDecorationTheme
                // `constraints: minHeight 44`; otherwise the decorator stays
                // 44px tall and top-aligns the text, so the typed value rides
                // ~10dp above the centered leading marker (Figma 6435:34680).
                constraints: BoxConstraints(),
                filled: false,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(
                  fontSize: 16,
                  height: 24 / 16,
                  leadingDistribution: TextLeadingDistribution.even,
                  fontWeight: FontWeight.w400,
                  color: FigmaPalette.label,
                ),
              ),
            ),
          ),
          // Clear-X appears once the field carries any text.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return Padding(
                // Figma Input gap=12 between the text group and the clear icon.
                padding: const EdgeInsets.only(left: 12),
                child: GestureDetector(
                  onTap: onClear,
                  behavior: HitTestBehavior.opaque,
                  child: const Icon(LucideIcons.circleX,
                      size: 20, color: FigmaPalette.label),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// The transport-type field of the search sheet — same 48px white rounded-12
/// pill as a location field, but with a leading truck glyph, an inline typeable
/// [TextField], and a trailing chevron that flips up while focused. The focused
/// field paints a 1.5px blue outline (Figma 6435:34680).
class _TransportField extends StatelessWidget {
  const _TransportField({
    required this.active,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final bool active;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        // Always-present 1.5px border (transparent when idle) so the glyph +
        // text never shift inward when the field gains focus.
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? FigmaPalette.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Center(
              child: Icon(
                LucideIcons.truck,
                size: 20,
                color: active ? FigmaPalette.primary : FigmaPalette.ink,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              cursorColor: FigmaPalette.primary,
              cursorWidth: 1.5,
              style: const TextStyle(
                fontSize: 16,
                height: 24 / 16,
                // Even leading splits the extra line height equally above and
                // below the glyphs so the text sits on the field's true vertical
                // centre (level with the leading icon), not riding high.
                leadingDistribution: TextLeadingDistribution.even,
                fontWeight: FontWeight.w400,
                color: FigmaPalette.countLabel,
              ),
              decoration: const InputDecoration(
                isCollapsed: true,
                // Clear the global inputDecorationTheme `constraints: minHeight
                // 44` so the collapsed decorator shrinks to text height and the
                // value sits level with the leading truck glyph, not ~10dp high.
                constraints: BoxConstraints(),
                filled: false,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                hintText: 'Transport turini tanlang',
                hintStyle: TextStyle(
                  fontSize: 16,
                  height: 24 / 16,
                  leadingDistribution: TextLeadingDistribution.even,
                  fontWeight: FontWeight.w400,
                  color: FigmaPalette.label,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            active ? LucideIcons.chevronUp : LucideIcons.chevronDown,
            size: 20,
            color: FigmaPalette.label,
          ),
        ],
      ),
    );
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
                Icon(LucideIcons.slidersHorizontal,
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
