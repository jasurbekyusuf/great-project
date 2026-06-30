import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_controller.dart';
import 'package:loadme_mobile/features/locations/presentation/providers/locations_providers.dart';
import 'package:loadme_mobile/features/magnit/presentation/providers/magnit_providers.dart';
import 'package:loadme_mobile/shared/design_system/ds_action_drawer.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';
import 'package:loadme_mobile/shared/design_system/ds_truck_type_drawer.dart';
import 'package:loadme_mobile/shared/widgets/app_svg_icon.dart';
import 'package:loadme_mobile/shared/widgets/frosted_header.dart';
import 'package:loadme_mobile/shared/widgets/select_location_drawer.dart';
import 'package:loadme_mobile/shared/widgets/swipe_back_wrapper.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Figma "Filtrlar" (node 6435:40358). A compact, mobile-native filter:
//   • grouped route card — Qayerdan + Radius (split) over Qayerga, linked by a
//     cube → flag dotted rail
//   • Transport turi tile, Kim joylagan tile (icon-box · label · value · ›)
//   • "Filterni tozalash" (red text) + full-width blue "Tayyor"
// Strings are hardcoded in Uzbek to match the mockup 1:1, like the other
// redesigned loads screens (e.g. the load detail page).
class LoadsFiltersScreen extends ConsumerStatefulWidget {
  const LoadsFiltersScreen({super.key});

  @override
  ConsumerState<LoadsFiltersScreen> createState() => _LoadsFiltersScreenState();
}

class _LoadsFiltersScreenState extends ConsumerState<LoadsFiltersScreen> {
  LocationItem? _from;
  LocationItem? _to;
  String? _radius;
  List<String> _selectedTrucks = [];
  List<String> _selectedPosters = [];

  // Anchors the Radius dropdown popover under the Radius field.
  final LayerLink _radiusLink = LayerLink();
  OverlayEntry? _radiusOverlay;

  static const _radii = ['50 km', '100 km', '150 km', '200 km', '300 km'];
  // Poster-filter options. Values are stable keys (display-only — not sent to
  // the backend); labels resolve via [_posterLabel] in all 4 languages.
  static const _posters = ['all', 'shipper', 'ai', 'broker'];

  String _posterLabel(String k) => switch (k) {
        'all' => 'filters.posterAll'.tr(ref),
        'shipper' => 'filters.posterShipper'.tr(ref),
        'ai' => 'LoadMe AI',
        _ => 'filters.posterBroker'.tr(ref),
      };

  @override
  void dispose() {
    _radiusOverlay?.remove();
    _radiusOverlay = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: FigmaPalette.sheetBg,
        body: Column(
          children: [
            FrostedHeader(title: 'filters.title'.tr(ref)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                children: [
                  _routeCard(),
                  const SizedBox(height: 8),
                  _FilterTile(
                    icon: const Icon(LucideIcons.truck,
                        size: 20, color: FigmaPalette.primary),
                    label: 'truckType.title'.tr(ref),
                    value: _selectedTrucks.isEmpty
                        ? 'search.selectTruckType'.tr(ref)
                        : _selectedTrucks.join(', '),
                    placeholder: _selectedTrucks.isEmpty,
                    onTap: _pickTruckType,
                  ),
                  const SizedBox(height: 8),
                  _FilterTile(
                    icon: const Icon(LucideIcons.user,
                        size: 20, color: FigmaPalette.primary),
                    label: 'filters.posterTitle'.tr(ref),
                    value: _selectedPosters.isEmpty
                        ? 'filters.posterHint'.tr(ref)
                        : _selectedPosters.map(_posterLabel).join(', '),
                    placeholder: _selectedPosters.isEmpty,
                    onTap: _pickPoster,
                  ),
                ],
              ),
            ),
            _BottomBar(
              onReset: _reset,
              // Figma gates "Tayyor" on the required "Qayerdan" field.
              onApply: _from == null ? null : _apply,
              resetLabel: 'filters.clearAll'.tr(ref),
              applyLabel: 'loadForm.ready'.tr(ref),
            ),
          ],
        ),
      ),
    );
  }

  // Qayerdan + Radius (top, split by a divider) over Qayerga, with a cube → flag
  // dotted rail on the left tying the two stops together.
  Widget _routeCard() {
    return Container(
      // White card on the #F3F4F7 sheet. Figma's stroke is visible:false, so
      // there is NO border — the card reads via fill contrast alone.
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left rail: cube · dotted · flag.
            Column(
              children: [
                _IconBox(
                  child: appSvgIcon('card_cube',
                      size: 20, color: FigmaPalette.primary),
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Center(child: _VDottedLine()),
                  ),
                ),
                _IconBox(
                  child: appSvgIcon('card_flag',
                      size: 20, color: FigmaPalette.primary),
                ),
              ],
            ),
            const SizedBox(width: 8),
            // Right content.
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _Field(
                              label: 'common.from'.tr(ref),
                              value:
                                  _from?.title ?? 'location.pickupTitle'.tr(ref),
                              placeholder: _from == null,
                              onTap: _pickFrom,
                              isRequired: true,
                            ),
                          ),
                          // 14 (gap) + 1 (divider) + 14 (gap); the divider line
                          // itself is the Positioned overlay below.
                          const SizedBox(width: 29),
                          CompositedTransformTarget(
                            link: _radiusLink,
                            child: SizedBox(
                              width: 84,
                              child: _Field(
                                label: 'magnit.radius'.tr(ref),
                                value: _radius ?? 'magnit.choose'.tr(ref),
                                placeholder: _radius == null,
                                onTap: _pickRadius,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFD5D9E1),
                      ),
                      const SizedBox(height: 10),
                      _Field(
                        label: 'common.to'.tr(ref),
                        value: _to?.title ?? 'location.deliveryTitle'.tr(ref),
                        placeholder: _to == null,
                        onTap: _pickTo,
                      ),
                    ],
                  ),
                  // Qayerdan↔Radius divider. Figma (6435:40987 · Rectangle
                  // 11765) draws it 1×63 centred on the 41px top row, so it
                  // overflows ~11px above the labels and meets the horizontal
                  // divider below (card y=1→64; horizontal divider at y=63.5).
                  // Pinned to the right (Radius col 84 + 14 gap = 98) so it
                  // stays put at any screen width.
                  const Positioned(
                    right: 98,
                    top: -11,
                    width: 1,
                    height: 63,
                    child: ColoredBox(color: FigmaPalette.divider),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFrom() async {
    final v = await showSelectLocationDrawer(
      context: context,
      isDestination: false,
      currentId: _from?.id,
    );
    if (v != null) setState(() => _from = v);
  }

  Future<void> _pickTo() async {
    final v = await showSelectLocationDrawer(
      context: context,
      isDestination: true,
      // Destination is optional in the filter, so "Har qanday joyga" is a real
      // pick (anywhere sentinel) meaning "don't constrain the delivery side".
      allowAnywhere: true,
      currentId: _to?.id,
    );
    if (v != null) setState(() => _to = v);
  }

  // Figma radius selection (6435:40853) is a dropdown popover anchored under
  // the Radius field — not a bottom sheet. Toggle it open/closed.
  void _pickRadius() {
    if (_radiusOverlay != null) {
      _closeRadiusPopover();
      return;
    }
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // Tap-outside scrim to dismiss.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeRadiusPopover,
            ),
          ),
          CompositedTransformFollower(
            link: _radiusLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, 8),
            child: _RadiusPopover(
              radii: _radii,
              selected: _radius,
              onPick: (v) {
                setState(() => _radius = v);
                _closeRadiusPopover();
              },
            ),
          ),
        ],
      ),
    );
    _radiusOverlay = entry;
    overlay.insert(entry);
  }

  void _closeRadiusPopover() {
    _radiusOverlay?.remove();
    _radiusOverlay = null;
  }

  Future<void> _pickTruckType() async {
    final v = await showDsTruckTypeDrawer(
      context: context,
      initialSelected: _selectedTrucks,
    );
    if (v != null) setState(() => _selectedTrucks = v);
  }

  Future<void> _pickPoster() async {
    final v = await showDsCheckSheet<String>(
      context: context,
      title: 'filters.posterTitle'.tr(ref),
      items:
          _posters.map((e) => DsSelectItem(value: e, label: _posterLabel(e))).toList(),
      initialSelected: _selectedPosters,
    );
    if (v != null) setState(() => _selectedPosters = v);
  }

  void _reset() {
    setState(() {
      _from = null;
      _to = null;
      _radius = null;
      _selectedTrucks = [];
      _selectedPosters = [];
    });
    // Clearing the visible fields isn't enough — the marketplace stays narrowed
    // until the *applied* server filter is cleared too, and "Tayyor" can't do it
    // (it disables the moment "Qayerdan" is empty). So drop the active filter and
    // pop, mirroring _apply, so the user lands back on the full, unfiltered feed.
    ref.read(loadsControllerProvider.notifier).applyLocationFilter({});
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/loads');
    }
  }

  Future<void> _apply() async {
    // Server-side filter: the picked place's kind decides the param
    // (`pickup_region` / `delivery_district` / …) and its id is the value, so
    // the whole marketplace is narrowed — exactly like the web load filter.
    final filters = <String, String>{};
    final from = _from;
    final to = _to;
    if (from != null) filters['pickup_${from.filterKey}'] = from.id;
    // "Har qanday joyga" (anywhere) carries no place id — it means leave the
    // delivery side unconstrained, so emit no `delivery_*` param.
    if (to != null && !to.isAnywhere) {
      filters['delivery_${to.filterKey}'] = to.id;
    }
    // Transport turi → `truck_type` (comma-joined backend UUIDs). The picker
    // hands back hardcoded Uzbek labels, so resolve them against the
    // `/trucks/types/` directory; without this the param was simply never sent
    // and the filter had no effect ("Bu filterlar ishlamayapti").
    if (_selectedTrucks.isNotEmpty) {
      try {
        final types = await ref.read(truckTypesProvider.future);
        final ids = resolveTruckTypeIds(types, _selectedTrucks);
        if (ids.isNotEmpty) filters['truck_type'] = ids.join(',');
      } catch (_) {
        // Directory fetch failed — apply the other filters rather than block.
      }
    }
    // E'lon egasi → `owner_role` (shipper|broker, comma-joined). "all"/"ai"
    // carry no backend role, so they are dropped (an empty set = no filter).
    final roles =
        _selectedPosters.where((p) => p == 'shipper' || p == 'broker').toList();
    if (roles.isNotEmpty) filters['owner_role'] = roles.join(',');
    // Radius (Yukgacha) → `pickup_anchor=lat,lng&deadhead_km` on
    // `/loads/available/`. The backend anchors the radius at the user's standing
    // location, so we attach the device's current GPS fix. A picked place has no
    // coordinates, hence GPS is the only anchor source; if it's unavailable
    // (permission denied / service off) the radius is skipped and the remaining
    // filters still apply rather than blocking the whole search.
    final radius = _radius;
    if (radius != null) {
      final km = RegExp(r'\d+').firstMatch(radius)?.group(0);
      final coords = await currentDeviceLatLng();
      if (km != null && coords != null) {
        filters['pickup_anchor'] = '${coords.lat},${coords.lng}';
        filters['deadhead_km'] = km;
      }
    }
    if (!mounted) return;
    ref.read(loadsControllerProvider.notifier).applyLocationFilter(filters);
    // Pop back to the previous list (preserves history); fall back to /loads
    // if filters was opened as a fresh root (e.g. a deep link).
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/loads');
    }
  }
}

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

const _labelStyle = TextStyle(
  fontSize: 12,
  height: 14.5 / 12,
  fontWeight: FontWeight.w400,
  color: FigmaPalette.countLabel,
);
const _valueStyle = TextStyle(
  fontSize: 16,
  height: 24 / 16,
  fontWeight: FontWeight.w400,
  color: FigmaPalette.countLabel,
);
const _hintStyle = TextStyle(
  fontSize: 16,
  height: 24 / 16,
  fontWeight: FontWeight.w400,
  color: FigmaPalette.label,
);

/// Label-over-value with a trailing chevron. Tap handling is owned by the
/// parent so the whole tile (icon included) is hittable.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    required this.placeholder,
    this.onTap,
    this.isRequired = false,
  });

  final String label;
  final String value;
  final bool placeholder;
  final VoidCallback? onTap;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Figma marks "Qayerdan" as required with a trailing red asterisk.
              if (isRequired)
                Text.rich(
                  TextSpan(
                    text: label,
                    style: _labelStyle,
                    children: const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: FigmaPalette.dangerText),
                      ),
                    ],
                  ),
                )
              else
                Text(label, style: _labelStyle),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: placeholder ? _hintStyle : _valueStyle,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(LucideIcons.chevronRight, size: 16, color: FigmaPalette.ink),
      ],
    );
    if (onTap == null) return row;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: row,
    );
  }
}

/// Gray rounded square holding a glyph. Route stops use 36/r12, the
/// standalone filter tiles 32/r10.
class _IconBox extends StatelessWidget {
  const _IconBox({required this.child, this.size = 36, this.radius = 12});
  final Widget child;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // Figma icon-tile bg (#EAEFF5) — a light blue-gray, not neutral gray.
        color: FigmaPalette.notifIconTile,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}

/// Standalone filter row: white r16 card with icon-box, field and chevron.
class _FilterTile extends StatelessWidget {
  const _FilterTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final String value;
  final bool placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        // No border — Figma's card stroke is visible:false (fill contrast only).
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _IconBox(size: 32, radius: 10, child: icon),
            const SizedBox(width: 8),
            Expanded(
              child: _Field(
                label: label,
                value: value,
                placeholder: placeholder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vertical dotted line that fills its allotted height (cube → flag rail).
class _VDottedLine extends StatelessWidget {
  const _VDottedLine();

  @override
  Widget build(BuildContext context) {
    // A bare CustomPaint collapses to Size.zero under the Center's loose
    // constraints, so the dashes never paint. Pin a fixed 18px height — Figma's
    // "Line 571" is exactly 18px (3 dashes: 3px on / 3px off). A finite height
    // (NOT double.infinity) is essential: this sits inside IntrinsicHeight,
    // whose layout asserts the child's intrinsic height is finite.
    return const SizedBox(
      width: 2,
      height: 18,
      child: CustomPaint(painter: _VDots()),
    );
  }
}

class _VDots extends CustomPainter {
  const _VDots();

  @override
  void paint(Canvas canvas, Size size) {
    // Figma (6435:40987 · "Line 571"): #98A2B3, 1.5px, dash 3 / gap 3, butt
    // caps so each dash is exactly 3px (round caps would bleed into the gaps).
    final paint = Paint()
      ..color = FigmaPalette.label
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.butt;
    const dot = 3.0;
    const gap = 3.0;
    final x = size.width / 2;
    var y = 0.0;
    while (y < size.height) {
      final end = (y + dot) > size.height ? size.height : y + dot;
      canvas.drawLine(Offset(x, y), Offset(x, end), paint);
      y += dot + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _VDots oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Radius dropdown popover (Figma 6435:40853) — anchored under the Radius field
// ---------------------------------------------------------------------------

/// White r16 card, 199 wide, five ~40px rows; the selected radius row shows a
/// primary checkmark on the right. Rendered in an Overlay via a
/// CompositedTransformFollower so it floats under the Radius field.
class _RadiusPopover extends StatelessWidget {
  const _RadiusPopover({
    required this.radii,
    required this.selected,
    required this.onPick,
  });

  final List<String> radii;
  final String? selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 199,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x29101828), // #101828 @ 16%
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final r in radii)
              InkWell(
                onTap: () => onPick(r),
                child: SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          r,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 18 / 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF131313),
                          ),
                        ),
                      ),
                      if (r == selected)
                        const Padding(
                          padding: EdgeInsets.only(right: 16),
                          // Figma checkmark is black (#000000), not primary blue.
                          child: Icon(LucideIcons.check,
                              size: 16, color: Color(0xFF000000)),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sticky bottom bar — "Filterni tozalash" (red) + "Tayyor"
// ---------------------------------------------------------------------------

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.onReset,
    required this.onApply,
    required this.resetLabel,
    required this.applyLabel,
  });

  final VoidCallback onReset;
  // Null disables "Tayyor" (Figma's empty state, gated on the required field).
  final VoidCallback? onApply;
  final String resetLabel;
  final String applyLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onReset,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  resetLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w500,
                    color: FigmaPalette.dangerText,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            DsButton(label: applyLabel, onPressed: onApply),
          ],
        ),
      ),
    );
  }
}
