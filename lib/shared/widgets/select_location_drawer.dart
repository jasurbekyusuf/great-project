import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/features/locations/domain/entities/location_entity.dart';
import 'package:loadme_mobile/features/locations/presentation/providers/locations_providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Figma "Yuk olish manzili" / "Yetkazish manzili" location search
// (Frame 2087329767). A full-screen sheet that slides up over the caller with
// rounded top corners, an auto-focused 56-tall input and a white suggestions
// card. The list is the real `/locations/search/` directory (same endpoint the
// web load filter uses), debounced through [locationSearchProvider].

/// The user's picked place. Carries the [kind] + [id] so the loads feed can be
/// filtered server-side (`pickup_<filterKey>` / `delivery_<filterKey>` = [id]).
class LocationItem {
  const LocationItem({
    required this.id,
    required this.title,
    required this.country,
    this.kind = LocationFilterKind.region,
    this.regionName,
  });

  /// Builds the lightweight selection item from a directory entity.
  factory LocationItem.fromEntity(LocationEntity e) => LocationItem(
        id: e.id,
        title: e.name,
        country: e.countryName ?? '',
        kind: e.kind,
        regionName: e.regionName,
      );

  final String id;
  final String title;

  /// Country label (e.g. "Oʻzbekiston") — empty for a country pick.
  final String country;

  /// Whether [id] is a country / region / district — picks the filter param.
  final LocationFilterKind kind;

  /// Parent region (district picks), for disambiguation in callers.
  final String? regionName;

  /// `/loads/available/` param suffix: `country` | `region` | `district`.
  String get filterKey => kind.name;
}

// Icon-box fill behind the pickup/delivery glyph (Figma #EBEBEB — distinct from
// the lighter chip grey used elsewhere).
const _kIconBoxBg = Color(0xFFEBEBEB);

/// Slides up the Figma location-search sheet and resolves with the tapped
/// [LocationItem] (or `null` if dismissed). [isDestination] swaps the pickup
/// styling (cube glyph, "Yuk olish manzili", "Mening joylashuvim") for the
/// delivery one (flag glyph, "Yetkazish manzili", "Har qanday joyga").
///
/// [currentId] is accepted for source compatibility; the redesign shows no
/// per-row selection state so it is currently unused.
Future<LocationItem?> showSelectLocationDrawer({
  required BuildContext context,
  bool isDestination = false,
  String? currentId,
}) {
  return Navigator.of(context).push<LocationItem>(
    PageRouteBuilder<LocationItem>(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) =>
          _LocationSearchPage(isDestination: isDestination),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
  );
}

class _LocationSearchPage extends ConsumerStatefulWidget {
  const _LocationSearchPage({required this.isDestination});
  final bool isDestination;

  @override
  ConsumerState<_LocationSearchPage> createState() =>
      _LocationSearchPageState();
}

class _LocationSearchPageState extends ConsumerState<_LocationSearchPage> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dest = widget.isDestination;
    final topInset = MediaQuery.of(context).padding.top;
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    final q = _query.trim();

    // The suggestions card is the "Har qanday…" action row followed by the live
    // results (or a loading / empty / error status row once a query is typed).
    final children = <Widget>[
      _ActionRow(
        icon: dest ? LucideIcons.mapPinned : LucideIcons.navigation,
        label: dest
            ? 'location.anywhere'.tr(ref)
            : 'location.myLocation'.tr(ref),
        onTap: () => Navigator.of(context).pop(),
      ),
    ];
    if (q.isNotEmpty) {
      ref.watch(locationSearchProvider(q)).when(
            data: (items) {
              if (items.isEmpty) {
                children
                  ..add(const _RowDivider())
                  ..add(_StatusRow.message('common.notFound'.tr(ref)));
              } else {
                for (final e in items) {
                  children
                    ..add(const _RowDivider())
                    ..add(_CityRow(
                      loc: e,
                      onTap: () =>
                          Navigator.of(context).pop(LocationItem.fromEntity(e)),
                    ));
                }
              }
            },
            loading: () => children
              ..add(const _RowDivider())
              ..add(const _StatusRow.loading()),
            error: (_, __) => children
              ..add(const _RowDivider())
              ..add(_StatusRow.message('common.searchError'.tr(ref))),
          );
    }

    return Padding(
      // Leave the OS status-bar strip so the caller peeks above the sheet's
      // rounded top corners, mirroring the iOS modal in Figma.
      padding: EdgeInsets.only(top: topInset),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Material(
          color: FigmaPalette.pageBg,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + keyboard),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header: ✕ + title (Frame Checkbox, gap 16).
                  Row(
                    children: [
                      _CloseButton(onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          dest
                              ? 'location.deliveryTitle'.tr(ref)
                              : 'location.pickupTitle'.tr(ref),
                          style: const TextStyle(
                            fontSize: 16,
                            height: 24 / 16,
                            fontWeight: FontWeight.w600,
                            color: FigmaPalette.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Input (always focused → blue border).
                  _SearchInput(
                    controller: _controller,
                    isDestination: dest,
                    onChanged: (v) => setState(() => _query = v),
                    onClear: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  ),
                  const SizedBox(height: 12),
                  // Suggestions card — hugs its content, scrolls when it grows.
                  Flexible(
                    child: SingleChildScrollView(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: children,
                          ),
                        ),
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
  }
}

/// 24×24 tap target holding the Figma ✕ glyph.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: const SizedBox(
        width: 24,
        height: 24,
        child: Icon(LucideIcons.x, size: 20, color: FigmaPalette.ink),
      ),
    );
  }
}

/// Figma Input [343×56] — white, r16, blue 1.5 border, an #EBEBEB icon box and
/// the search field, plus a clear-✕ that appears once text is entered.
class _SearchInput extends ConsumerWidget {
  const _SearchInput({
    required this.controller,
    required this.isDestination,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool isDestination;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasText = controller.text.isNotEmpty;
    return Container(
      height: 56,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FigmaPalette.primary, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _kIconBoxBg,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              isDestination ? LucideIcons.flag : LucideIcons.box,
              size: 20,
              color: FigmaPalette.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              onChanged: onChanged,
              cursorColor: FigmaPalette.primary,
              cursorWidth: 1.5,
              style: const TextStyle(
                fontSize: 16,
                height: 24 / 16,
                leadingDistribution: TextLeadingDistribution.even,
                fontWeight: FontWeight.w400,
                color: FigmaPalette.countLabel,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                hintText: isDestination
                    ? 'common.to'.tr(ref)
                    : 'common.from'.tr(ref),
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
          if (hasText) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onClear,
              behavior: HitTestBehavior.opaque,
              child: const Icon(LucideIcons.circleX,
                  size: 20, color: FigmaPalette.label),
            ),
          ],
        ],
      ),
    );
  }
}

/// First suggestion row — "Mening joylashuvim" (pickup) / "Har qanday joyga"
/// (delivery) with a leading navigation / map-pin glyph.
class _ActionRow extends StatelessWidget {
  const _ActionRow(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Icon(icon, size: 20, color: FigmaPalette.inkStrong),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  height: 18 / 14,
                  fontWeight: FontWeight.w400,
                  color: FigmaPalette.inkStrong,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// City suggestion row — a pin glyph, the place name and a muted
/// "region, country" subtitle (Figma 343×52, grows for the second line).
class _CityRow extends StatelessWidget {
  const _CityRow({required this.loc, required this.onTap});
  final LocationEntity loc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = loc.subtitle;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            const SizedBox(
              width: 24,
              child:
                  Icon(LucideIcons.mapPin, size: 18, color: FigmaPalette.label),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 18 / 14,
                      fontWeight: FontWeight.w400,
                      color: FigmaPalette.inkStrong,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A loading / empty / error placeholder row inside the suggestions card.
class _StatusRow extends StatelessWidget {
  const _StatusRow.loading()
      : _loading = true,
        _message = null;
  const _StatusRow.message(String message)
      : _loading = false,
        _message = message;

  final bool _loading;
  final String? _message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: FigmaPalette.primary,
              ),
            )
          : Text(
              _message ?? '',
              style: const TextStyle(
                fontSize: 14,
                height: 18 / 14,
                fontWeight: FontWeight.w400,
                color: FigmaPalette.label,
              ),
            ),
    );
  }
}

/// Full-bleed hairline between suggestion rows.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: FigmaPalette.divider);
  }
}
