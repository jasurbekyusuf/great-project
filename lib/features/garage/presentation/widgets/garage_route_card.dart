import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/shared/widgets/app_svg_icon.dart';
import 'package:loadme_mobile/shared/widgets/card_action_menu.dart';
import 'package:loadme_mobile/shared/widgets/load_card_parts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Figma "Yo'nalishlarim" route card (node 6602-20760, frame 2087329702):
/// avatar + stacked name/price + 3-dot menu, route block, then footer stats
/// with an iOS active/paused toggle.
class GarageRouteCard extends StatelessWidget {
  const GarageRouteCard({
    super.key,
    required this.name,
    required this.priceLabel,
    required this.fromCity,
    required this.fromCountry,
    required this.toCity,
    required this.toCountry,
    required this.distanceKm,
    required this.weightT,
    required this.loadKind,
    required this.active,
    required this.onToggle,
    required this.menuActions,
    this.onTap,
    this.avatarUrl,
  });

  final String name;
  final String priceLabel;
  final String fromCity;
  final String fromCountry;
  final String toCity;
  final String toCountry;
  final int distanceKm;
  final double weightT;
  final String loadKind;
  final bool active;
  final ValueChanged<bool> onToggle;
  final List<CardMenuAction> menuActions;
  final VoidCallback? onTap;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return FigmaCardShell(
      onTap: onTap ?? () {},
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: avatar + name/price + 3-dot menu ──────────────
          Row(
            children: [
              TruckAvatar(url: avatarUrl),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 18 / 14,
                        fontWeight: FontWeight.w500,
                        color: FigmaPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      priceLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                        color: FigmaPalette.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _MenuButton(actions: menuActions),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 1, thickness: 1, color: FigmaPalette.divider),
          const SizedBox(height: 6),

          // ── Route block ───────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 3),
                  appSvgIcon('card_cube', size: 12, color: FigmaPalette.inkStrong),
                  const DottedConnector(height: 14, width: 12, color: FigmaPalette.label),
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

          const SizedBox(height: 6),
          const Divider(height: 1, thickness: 1, color: FigmaPalette.divider),
          const SizedBox(height: 6),

          // ── Footer: stats + active toggle ─────────────────────────
          Row(
            children: [
              RouteStatChip(
                icon: appSvgIcon('card_route', size: 16, color: FigmaPalette.inkStrong),
                text: '$distanceKm km',
                gap: 3,
              ),
              const SizedBox(width: 8),
              const CardVDivider(),
              const SizedBox(width: 8),
              RouteStatChip(
                icon: appSvgIcon('card_weight', size: 16, color: FigmaPalette.inkStrong),
                text: '${formatQty(weightT)} t',
                gap: 3,
              ),
              const SizedBox(width: 8),
              const CardVDivider(),
              const SizedBox(width: 8),
              RouteStatChip(
                icon: appSvgIcon('card_full', size: 16, color: FigmaPalette.inkStrong),
                text: loadKind,
                gap: 3,
              ),
              const Spacer(),
              // iOS-style toggle (Figma 51×31, track #65C466 when on).
              SizedBox(
                height: 31,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: CupertinoSwitch(
                    value: active,
                    activeTrackColor: const Color(0xFF65C466),
                    onChanged: onToggle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.actions});
  final List<CardMenuAction> actions;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showCardActionMenu(context: context, actions: actions),
        child: const SizedBox(
          width: 32,
          height: 32,
          child: Icon(LucideIcons.ellipsisVertical, size: 20, color: FigmaPalette.ink),
        ),
      ),
    );
  }
}
