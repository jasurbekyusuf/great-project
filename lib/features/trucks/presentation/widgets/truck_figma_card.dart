import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/shared/widgets/app_svg_icon.dart';
import 'package:loadme_mobile/shared/widgets/load_card_parts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Figma "Transport" card (transport-tab-page, node 6440:60043 variant).
///
/// Layout (top → bottom, sections split by 1px dividers):
///   1. Header — avatar + truck model name (left)         price (right, blue)
///   2. Route  — cube + from city + country code
///               flag + to   city + country code
///   3. Footer — 328 km · 33 t · To'liq                   "X min oldin"
class TruckFigmaCard extends StatelessWidget {
  const TruckFigmaCard({
    super.key,
    required this.truckName,
    required this.priceLabel,
    required this.fromCity,
    required this.fromCountry,
    required this.toCity,
    required this.toCountry,
    required this.onTap,
    this.distanceKm,
    this.weightT,
    this.loadKind,
    this.timeAgo,
    this.avatarUrl,
  });

  final String truckName;
  final String priceLabel;
  final String fromCity;
  final String fromCountry;
  final String toCity;
  final String toCountry;
  final VoidCallback onTap;
  final int? distanceKm;
  final double? weightT;
  final String? loadKind;
  final String? timeAgo;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return FigmaCardShell(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Header: avatar + name | price ──────────────────
          Row(
            children: [
              _Avatar(url: avatarUrl),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  truckName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 18 / 14,
                    fontWeight: FontWeight.w500,
                    color: FigmaPalette.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                priceLabel,
                style: const TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w600,
                  color: FigmaPalette.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, thickness: 1, color: FigmaPalette.divider),
          const SizedBox(height: 6),

          // ── 2. Route: cube · dotted · flag icon column + cities ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 3),
                  appSvgIcon('card_cube', size: 12, color: FigmaPalette.inkStrong),
                  const DottedConnector(
                      height: 14, width: 12, color: FigmaPalette.label),
                  appSvgIcon('card_flag', size: 12, color: FigmaPalette.inkStrong),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RouteCityRow(city: fromCity, country: fromCountry),
                    const SizedBox(height: 6),
                    RouteCityRow(city: toCity, country: toCountry),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, thickness: 1, color: FigmaPalette.divider),
          const SizedBox(height: 6),

          // ── 3. Footer ─────────────────────────────────────────
          Row(
            children: [
              if (distanceKm != null) ...[
                RouteStatChip(
                  icon: appSvgIcon('card_route',
                      size: 16, color: FigmaPalette.inkStrong),
                  text: '$distanceKm km',
                  gap: 3,
                  color: FigmaPalette.ink,
                ),
                const SizedBox(width: 8),
                const CardVDivider(),
                const SizedBox(width: 8),
              ],
              if (weightT != null) ...[
                RouteStatChip(
                  icon: appSvgIcon('card_weight',
                      size: 16, color: FigmaPalette.inkStrong),
                  text: '${formatQty(weightT!)} t',
                  gap: 3,
                  color: FigmaPalette.ink,
                ),
                const SizedBox(width: 8),
                const CardVDivider(),
                const SizedBox(width: 8),
              ],
              if (loadKind != null)
                RouteStatChip(
                  icon: appSvgIcon('card_full',
                      size: 16, color: FigmaPalette.inkStrong),
                  text: loadKind!,
                  gap: 3,
                  color: FigmaPalette.ink,
                ),
              const Spacer(),
              if (timeAgo != null)
                Text(
                  timeAgo!,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 18 / 12,
                    fontWeight: FontWeight.w500,
                    color: FigmaPalette.muted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: FigmaPalette.avatarBg,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null
          // 40 logical px @ ~2x DPR — decode small to keep list scrolling light.
          ? Image.network(url!, fit: BoxFit.cover, cacheWidth: 80)
          : const Icon(LucideIcons.truck, size: 20, color: FigmaPalette.muted),
    );
  }
}
