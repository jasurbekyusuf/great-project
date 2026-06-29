import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/core/utils/address_format.dart';
import 'package:loadme_mobile/features/loads/domain/entities/load_entity.dart';
import 'package:loadme_mobile/shared/widgets/app_svg_icon.dart';
import 'package:loadme_mobile/shared/widgets/load_card_parts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Pixel-faithful port of the Figma `Search` page load card
// (frame 2087329682, 343×158, r=16, padding 10/16, gap=4).
//
// Three sections separated by 1px dividers:
//   1. Header — verified ✓ + owner + rating ⭐               role badge pill
//   2. Route  — cube/flag icon column + radius (left) / price (right),
//               from city + country, to city + country + truck-type chip
//   3. Footer — distance · weight · volume                  timestamp
class LoadFigmaCard extends StatelessWidget {
  const LoadFigmaCard({
    super.key,
    required this.load,
    required this.onTap,
    this.ownerName = 'LoadMe admin',
    this.ownerRating,
    this.verified = false,
    this.priceLabel,
    this.fromCountry = 'UZ',
    this.toCountry = 'UZ',
    this.roleBadge,
    this.truckType = 'Tent',
    this.loadKind,
    this.distanceKm,
    this.deadHeadKm,
    this.volumeM3,
    this.weightT,
    this.radiusKm,
    this.timeAgo,
  });

  final LoadEntity load;
  final VoidCallback onTap;
  final String ownerName;
  final double? ownerRating;
  final bool verified;
  final String? priceLabel;
  final String fromCountry;
  final String toCountry;
  final String? roleBadge;
  final String truckType;
  final String? loadKind;
  final int? distanceKm;
  final int? deadHeadKm;
  final double? volumeM3;
  final double? weightT;
  final int? radiusKm;
  final String? timeAgo;

  @override
  Widget build(BuildContext context) {
    return FigmaCardShell(
      onTap: onTap,
      color: context.colors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderRow(
            ownerName: ownerName,
            ownerRating: ownerRating,
            verified: verified,
            roleBadge: roleBadge,
          ),
          const SizedBox(height: 4),
          const Divider(height: 1, thickness: 1, color: FigmaPalette.divider),
          const SizedBox(height: 8),
          _RouteBlock(
            radiusKm: radiusKm ?? deadHeadKm,
            priceLabel: priceLabel,
            fromCity: addressCity(load.fromAddress),
            fromCountry: fromCountry,
            toCity: addressCity(load.toAddress),
            toCountry: toCountry,
            truckType: truckType,
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, thickness: 1, color: FigmaPalette.divider),
          const SizedBox(height: 8),
          _FooterRow(
            distanceKm: distanceKm,
            weightT: weightT,
            volumeM3: volumeM3,
            timeAgo: timeAgo,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.ownerName,
    required this.ownerRating,
    required this.verified,
    required this.roleBadge,
  });

  final String ownerName;
  final double? ownerRating;
  final bool verified;
  final String? roleBadge;

  static const _ownerStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: FigmaPalette.gray700,
    height: 18 / 14,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Owner identity group takes all the free width so the role badge is
        // always pinned to the right edge (and the name ellipsises instead of
        // shoving the badge inward).
        Expanded(
          child: Row(
            children: [
              if (verified) ...[
                // Exact Figma check-circle (gradient + white check baked in).
                appSvgIcon('card_verified', size: 12),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  ownerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _ownerStyle,
                ),
              ),
              if (ownerRating != null) ...[
                const SizedBox(width: 4),
                Text(ownerRating!.toStringAsFixed(1), style: _ownerStyle),
                const SizedBox(width: 2),
                // Exact Figma star (gold #FEC84B baked in → no tint).
                appSvgIcon('card_star', size: 14),
              ],
            ],
          ),
        ),
        if (roleBadge != null) ...[
          const SizedBox(width: 8),
          RoleBadge(label: roleBadge!),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Route block
// ---------------------------------------------------------------------------

class _RouteBlock extends StatelessWidget {
  const _RouteBlock({
    required this.radiusKm,
    required this.priceLabel,
    required this.fromCity,
    required this.fromCountry,
    required this.toCity,
    required this.toCountry,
    required this.truckType,
  });

  final int? radiusKm;
  final String? priceLabel;
  final String fromCity;
  final String fromCountry;
  final String toCity;
  final String toCountry;
  final String truckType;

  @override
  Widget build(BuildContext context) {
    final radiusLabel = ProviderScope.containerOf(context, listen: false)
        .read(appL10nProvider)
        .tr('magnit.radius');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _RouteIconColumn(),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Radius (left) + Price (right)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      radiusKm == null
                          ? '$radiusLabel: —'
                          : '$radiusLabel: ${radiusKm}km',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: FigmaPalette.muted,
                        height: 1.5,
                      ),
                    ),
                  ),
                  if (priceLabel != null)
                    Text(
                      priceLabel!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: FigmaPalette.primary,
                        height: 20 / 14,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              RouteCityRow(city: fromCity, country: fromCountry),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                      child: RouteCityRow(city: toCity, country: toCountry)),
                  _TruckTypeChip(label: truckType),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteIconColumn extends StatelessWidget {
  const _RouteIconColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 2),
        appSvgIcon('card_pin', size: 13, color: FigmaPalette.muted),
        const DottedConnector(height: 14),
        appSvgIcon('card_cube', size: 13, color: FigmaPalette.inkStrong),
        const DottedConnector(height: 14),
        appSvgIcon('card_flag', size: 13, color: FigmaPalette.inkStrong),
      ],
    );
  }
}

class _TruckTypeChip extends StatelessWidget {
  const _TruckTypeChip({required this.label});
  final String label;

  // Per-type icon: refrigerated → snowflake, cistern → fuel, jumbo →
  // container, otherwise a box truck (matches the Figma card variants).
  static IconData _iconFor(String label) {
    final l = label.toLowerCase();
    if (l.contains('refer') || l.contains('refr')) return LucideIcons.snowflake;
    if (l.contains('sisterna') || l.contains('tank') || l.contains('sistern')) {
      return LucideIcons.fuel;
    }
    if (l.contains('jumbo')) return LucideIcons.container;
    return LucideIcons.truck;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: FigmaPalette.chipBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(label), size: 12, color: FigmaPalette.ink),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: FigmaPalette.ink,
              height: 18 / 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Footer
// ---------------------------------------------------------------------------

class _FooterRow extends StatelessWidget {
  const _FooterRow({
    required this.distanceKm,
    required this.weightT,
    required this.volumeM3,
    required this.timeAgo,
  });

  final int? distanceKm;
  final double? weightT;
  final double? volumeM3;
  final String? timeAgo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (distanceKm != null) ...[
          RouteStatChip(
            icon: appSvgIcon('card_route',
                size: 14, color: FigmaPalette.inkStrong),
            text: '$distanceKm km',
          ),
          const SizedBox(width: 6),
          const CardVDivider(),
          const SizedBox(width: 6),
        ],
        if (weightT != null) ...[
          RouteStatChip(
            icon: appSvgIcon('card_weight',
                size: 14, color: FigmaPalette.inkStrong),
            text: '${formatQty(weightT!)} t',
          ),
          const SizedBox(width: 6),
        ],
        if (volumeM3 != null) ...[
          RouteStatChip(
            icon: appSvgIcon('card_cube',
                size: 14, color: FigmaPalette.inkStrong),
            text: '${formatQty(volumeM3!)} m³',
          ),
          const SizedBox(width: 6),
        ],
        const Spacer(),
        if (timeAgo != null)
          Text(
            timeAgo!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: FigmaPalette.muted,
              height: 1.5,
            ),
          ),
      ],
    );
  }
}
