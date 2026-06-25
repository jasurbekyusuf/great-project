import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_controller.dart';
import 'package:loadme_mobile/shared/design_system/ds_action_drawer.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';
import 'package:loadme_mobile/shared/design_system/ds_multi_select_drawer.dart';
import 'package:loadme_mobile/shared/design_system/ds_truck_type_drawer.dart';
import 'package:loadme_mobile/shared/widgets/app_svg_icon.dart';
import 'package:loadme_mobile/shared/widgets/frosted_header.dart';
import 'package:loadme_mobile/shared/widgets/select_location_drawer.dart';
import 'package:loadme_mobile/shared/widgets/swipe_back_wrapper.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Figma "Filtrlar" (node 6435:40358). A compact, mobile-native filter:
//   • grouped route card — Qayerdan + Radius (split) over Qayerga, linked by a
//     cube → flag dotted rail
//   • Transport turi tile, E'lon egasi tile (icon-box · label · value · ›)
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

  static const _radii = ['10 km', '25 km', '50 km', '100 km', '200 km'];
  static const _posters = [
    'Hammasi',
    'Yuk egasi',
    'LoadMe AI',
    'Logist / Dispatcher'
  ];

  @override
  Widget build(BuildContext context) {
    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: FigmaPalette.sheetBg,
        body: Column(
          children: [
            const FrostedHeader(title: 'Filtrlar'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                children: [
                  _routeCard(),
                  const SizedBox(height: 8),
                  _FilterTile(
                    icon: const Icon(LucideIcons.truck,
                        size: 20, color: FigmaPalette.primary),
                    label: 'Transport turi',
                    value: _selectedTrucks.isEmpty
                        ? 'Transport turini tanlang'
                        : _selectedTrucks.join(', '),
                    placeholder: _selectedTrucks.isEmpty,
                    onTap: _pickTruckType,
                  ),
                  const SizedBox(height: 8),
                  _FilterTile(
                    icon: const Icon(LucideIcons.user,
                        size: 20, color: FigmaPalette.primary),
                    label: 'E’lon egasi',
                    value: _selectedPosters.isEmpty
                        ? 'E’lon egasini tanlang'
                        : _selectedPosters.join(', '),
                    placeholder: _selectedPosters.isEmpty,
                    onTap: _pickPoster,
                  ),
                ],
              ),
            ),
            _BottomBar(onReset: _reset, onApply: _apply),
          ],
        ),
      ),
    );
  }

  // Qayerdan + Radius (top, split by a divider) over Qayerga, with a cube → flag
  // dotted rail on the left tying the two stops together.
  Widget _routeCard() {
    return Container(
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _Field(
                            label: 'Qayerdan',
                            isRequired: true,
                            value: _from?.title ?? 'Yuk olish manzili',
                            placeholder: _from == null,
                            onTap: _pickFrom,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: FigmaPalette.divider,
                        ),
                        const SizedBox(width: 14),
                        SizedBox(
                          width: 84,
                          child: _Field(
                            label: 'Radius',
                            value: _radius ?? 'Tanlang',
                            placeholder: _radius == null,
                            onTap: _pickRadius,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFD5D9E1),
                  ),
                  const SizedBox(height: 10),
                  _Field(
                    label: 'Qayerga',
                    value: _to?.title ?? 'Yetkazish manzili',
                    placeholder: _to == null,
                    onTap: _pickTo,
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
      currentId: _to?.id,
    );
    if (v != null) setState(() => _to = v);
  }

  Future<void> _pickRadius() async {
    final v = await _pickFromList('Radius', _radii, _radius);
    if (v != null) setState(() => _radius = v);
  }

  Future<void> _pickTruckType() async {
    final v = await showDsTruckTypeDrawer(
      context: context,
      initialSelected: _selectedTrucks,
    );
    if (v != null) setState(() => _selectedTrucks = v);
  }

  Future<void> _pickPoster() async {
    final v = await showDsMultiSelectDrawer<String>(
      context: context,
      title: 'Kim joylagan',
      items:
          _posters.map((e) => DsMultiSelectItem(value: e, label: e)).toList(),
      initialSelected: _selectedPosters,
    );
    if (v != null) setState(() => _selectedPosters = v);
  }

  Future<String?> _pickFromList(
    String title,
    List<String> items,
    String? current,
  ) {
    return showDsActionDrawer<String>(
      context: context,
      title: title,
      currentValue: current,
      items: items.map((t) => DsActionDrawerItem(value: t, label: t)).toList(),
    );
  }

  void _reset() {
    setState(() {
      _from = null;
      _to = null;
      _radius = null;
      _selectedTrucks = [];
      _selectedPosters = [];
    });
  }

  void _apply() {
    // Server-side filter: the picked place's kind decides the param
    // (`pickup_region` / `delivery_district` / …) and its id is the value, so
    // the whole marketplace is narrowed — exactly like the web load filter.
    final filters = <String, String>{};
    final from = _from;
    final to = _to;
    if (from != null) filters['pickup_${from.filterKey}'] = from.id;
    if (to != null) filters['delivery_${to.filterKey}'] = to.id;
    ref.read(loadsControllerProvider.notifier).applyLocationFilter(filters);
    // Pop back to the previous list (preserves history); fall back to /loads
    // if filters was opened as a fresh root (e.g. a deep link).
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
    this.isRequired = false,
    this.onTap,
  });

  final String label;
  final String value;
  final bool placeholder;

  /// Figma marks mandatory fields (only "Qayerdan") with a trailing red `*`.
  final bool isRequired;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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
        color: const Color(0xFFEBEBEB),
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
    return const SizedBox(width: 2, child: CustomPaint(painter: _VDots()));
  }
}

class _VDots extends CustomPainter {
  const _VDots();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = FigmaPalette.label
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dot = 2.0;
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
// Sticky bottom bar — "Filterni tozalash" (red) + "Tayyor"
// ---------------------------------------------------------------------------

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.onReset, required this.onApply});

  final VoidCallback onReset;
  final VoidCallback onApply;

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
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Filterni tozalash',
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w500,
                    color: FigmaPalette.dangerText,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            DsButton(label: 'Tayyor', onPressed: onApply),
          ],
        ),
      ),
    );
  }
}
