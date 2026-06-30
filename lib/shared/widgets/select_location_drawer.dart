import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/features/locations/domain/entities/location_entity.dart';
import 'package:loadme_mobile/features/locations/presentation/providers/location_status_provider.dart';
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
    this.countryId,
    this.regionId,
    this.latitude,
    this.longitude,
    this.isAnywhere = false,
  });

  /// The "Har qanday joyga" (anywhere) sentinel — a *non-null* selection that
  /// carries no place id, so callers can tell it apart from a dismissed sheet
  /// (which still pops `null`). Its filter getters all return null, so applying
  /// it simply clears the delivery constraint instead of narrowing it.
  const LocationItem.anywhere({required this.title})
      : id = '',
        country = '',
        kind = LocationFilterKind.region,
        regionName = null,
        countryId = null,
        regionId = null,
        latitude = null,
        longitude = null,
        isAnywhere = true;

  /// Builds the lightweight selection item from a directory entity.
  factory LocationItem.fromEntity(LocationEntity e) => LocationItem(
        id: e.id,
        title: e.name,
        country: e.countryName ?? '',
        kind: e.kind,
        regionName: e.regionName,
        countryId: e.countryId,
        regionId: e.regionId,
        latitude: e.latitude,
        longitude: e.longitude,
      );

  final String id;
  final String title;

  /// Country label (e.g. "Oʻzbekiston") — empty for a country pick.
  final String country;

  /// Whether [id] is a country / region / district — picks the filter param.
  final LocationFilterKind kind;

  /// Parent region (district picks), for disambiguation in callers.
  final String? regionName;

  /// Parent country / region **ids** (from the directory payload), so callers
  /// that need the full chain — e.g. magnet/route creation, where the backend
  /// requires `pickup_country` *and* `pickup_region` together — can resolve it.
  final String? countryId;
  final String? regionId;

  /// Place centroid, usable as a proximity (radius) anchor without device GPS.
  final double? latitude;
  final double? longitude;

  /// True only for the [LocationItem.anywhere] sentinel ("Har qanday joyga").
  final bool isAnywhere;

  /// `/loads/available/` param suffix: `country` | `region` | `district`.
  String get filterKey => kind.name;

  /// Caller-facing label: the anywhere sentinel shows its (already-localized)
  /// title alone, a normal pick keeps the "country · place" form.
  String get displayLabel =>
      isAnywhere || country.isEmpty ? title : '$country · $title';

  /// The full country→region→district chain for endpoints that need it.
  /// A region pick yields `{country, region}`; a district `{country, region,
  /// district}`; a country just `{country}`. Self id slots in by [kind]; the
  /// rest come from the carried parent ids.
  String? get countryFilterId => isAnywhere
      ? null
      : (kind == LocationFilterKind.country ? id : countryId);
  String? get regionFilterId => isAnywhere
      ? null
      : (kind == LocationFilterKind.region
          ? id
          : (kind == LocationFilterKind.district ? regionId : null));
  String? get districtFilterId =>
      isAnywhere ? null : (kind == LocationFilterKind.district ? id : null);
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
/// [allowAnywhere] turns the destination "Har qanday joyga" row into a real
/// selection ([LocationItem.anywhere]) rather than a dismiss — used by the
/// loads/magnit filters where "anywhere" clears the delivery constraint. It is
/// off for creation forms, where an explicit destination is required.
Future<LocationItem?> showSelectLocationDrawer({
  required BuildContext context,
  bool isDestination = false,
  bool allowAnywhere = false,
  String? currentId,
}) {
  return Navigator.of(context).push<LocationItem>(
    PageRouteBuilder<LocationItem>(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => _LocationSearchPage(
          isDestination: isDestination, allowAnywhere: allowAnywhere),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
  );
}

class _LocationSearchPage extends ConsumerStatefulWidget {
  const _LocationSearchPage(
      {required this.isDestination, this.allowAnywhere = false});
  final bool isDestination;
  final bool allowAnywhere;

  @override
  ConsumerState<_LocationSearchPage> createState() =>
      _LocationSearchPageState();
}

class _LocationSearchPageState extends ConsumerState<_LocationSearchPage> {
  final _controller = TextEditingController();
  String _query = '';
  // A "Mening joylashuvim" GPS lookup is in flight (spinner on the action row).
  bool _locating = false;
  // The place the last GPS reverse-geocode resolved to. While set (and the
  // search box is otherwise empty) it shows as a pinned, one-tap confirm row so
  // the user *sees* what their location resolved to in the input before it
  // propagates back to the caller.
  LocationEntity? _resolved;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// "Mening joylashuvim" (pickup only): take a GPS fix, reverse-geocode it to a
  /// directory place and surface it in the input. On success the resolved place
  /// name fills the search field and a pinned confirm row appears, so the user
  /// can see and confirm it (the original bug: nothing was ever shown). A null
  /// result means location is off/denied or unmatched — show a clear message and
  /// kick off the permission/settings flow so the user can grant access and try
  /// again, instead of silently doing nothing.
  Future<void> _useMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);

    // Step 1 — get a GPS fix. No coordinates means location access is the
    // problem (service off / permission denied) or the fix couldn't be obtained.
    // Check access to decide between routing to settings vs. just informing.
    final coords = await currentDeviceLatLng();
    if (!mounted) return;
    if (coords == null) {
      ref.invalidate(locationEnabledProvider);
      final hasAccess = await ref.read(locationEnabledProvider.future);
      if (!mounted) return;
      setState(() => _locating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hasAccess
              ? 'location.locateFailed'.tr(ref)
              : 'location.permissionNeeded'.tr(ref)),
        ),
      );
      if (!hasAccess) await enableLocation(ref);
      return;
    }

    // Step 2 — reverse-geocode the fix to a directory place. Surface the
    // backend's own error on failure (e.g. an unmatched coordinate or a network
    // issue) instead of a generic message, so the cause is visible.
    final result = await ref
        .read(locationsRepositoryProvider)
        .reverse(lat: coords.lat, lng: coords.lng);
    if (!mounted) return;
    setState(() => _locating = false);
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (place) {
        // A successful call can still yield no place — the backend matched the
        // request but found no region/district for these coordinates. Treat that
        // as a soft failure rather than crashing on a null name.
        if (place == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('location.locateFailed'.tr(ref))),
          );
          return;
        }
        _controller.text = place.name;
        setState(() {
          _resolved = place;
          _query = '';
        });
      },
    );
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
        // Destination "Har qanday joyga": when [allowAnywhere] is on it pops a
        // real anywhere-sentinel (so the caller applies it as "clear the
        // delivery constraint"); otherwise it just dismisses. Pickup "Mening
        // joylashuvim" resolves the device GPS to a place.
        loading: !dest && _locating,
        onTap: dest
            ? () => Navigator.of(context).pop(
                  widget.allowAnywhere
                      ? LocationItem.anywhere(title: 'location.anywhere'.tr(ref))
                      : null,
                )
            : _useMyLocation,
      ),
    ];
    // Pinned GPS result: shown only while no query is typed, so it never
    // competes with live search. Tapping it confirms the resolved place.
    if (q.isEmpty && _resolved != null) {
      children
        ..add(const _RowDivider())
        ..add(_CityRow(
          loc: _resolved!,
          onTap: () =>
              Navigator.of(context).pop(LocationItem.fromEntity(_resolved!)),
        ));
    }
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
                      setState(() {
                        _query = '';
                        _resolved = null;
                      });
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
      {required this.icon,
      required this.label,
      required this.onTap,
      this.loading = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Swaps the leading glyph for a spinner while a GPS lookup is in flight.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: FigmaPalette.primary,
                      ),
                    )
                  : Icon(icon, size: 20, color: FigmaPalette.inkStrong),
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
