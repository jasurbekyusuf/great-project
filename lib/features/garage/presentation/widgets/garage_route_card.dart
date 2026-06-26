import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/shared/widgets/app_svg_icon.dart';
import 'package:loadme_mobile/shared/widgets/card_action_menu.dart';
import 'package:loadme_mobile/shared/widgets/load_card_parts.dart';

/// Figma "Yo'nalishlarim" route card (node 6751-17736, frame 2087329702):
/// avatar + name/plate on the left with the price pinned right, a route block,
/// then a "Magnit funksiyasi" row with an iOS toggle.
///
/// The redesign dropped the visible 3-dot menu, so edit/archive/delete now live
/// on a long-press of the card (kept reachable, but invisible per the design).
class GarageRouteCard extends StatelessWidget {
  const GarageRouteCard({
    super.key,
    required this.name,
    required this.priceLabel,
    required this.fromCity,
    required this.fromCountry,
    required this.toCity,
    required this.toCountry,
    required this.active,
    required this.magnitLabel,
    required this.onToggle,
    required this.menuActions,
    this.plate = '',
    this.onTap,
    this.avatarUrl,
  });

  final String name;
  final String plate;
  final String priceLabel;
  final String fromCity;
  final String fromCountry;
  final String toCity;
  final String toCountry;
  final bool active;

  /// Resolved label for the toggle row — "Magnit funksiyasi" (off) or
  /// "Magnit funksiyasi yoqilgan" (on); supplied by the screen via l10n.
  final String magnitLabel;
  final ValueChanged<bool> onToggle;
  final List<CardMenuAction> menuActions;
  final VoidCallback? onTap;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final card = FigmaCardShell(
      onTap: onTap ?? () {},
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: avatar + name/plate | price ───────────────────
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
                    if (plate.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        plate,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 14.5 / 12,
                          fontWeight: FontWeight.w400,
                          color: FigmaPalette.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
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

          const SizedBox(height: 6),
          const Divider(height: 1, thickness: 1, color: FigmaPalette.divider),
          const SizedBox(height: 6),

          // ── Footer: Magnit-function row + iOS toggle ──────────────
          Row(
            children: [
              // The magnet glyph only shows when the function is off; the "on"
              // row is text-only (Figma 6751:17736). Uses the stylised Magnit
              // brand glyph (recoloured to ink) — not the plain Lucide magnet.
              if (!active) ...[
                Image.asset(
                  'assets/images/magnit_glyph.png',
                  width: 20,
                  height: 20,
                  color: FigmaPalette.inkStrong,
                  colorBlendMode: BlendMode.srcIn,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  magnitLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 18 / 14,
                    fontWeight: FontWeight.w400,
                    color: FigmaPalette.ink,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // iOS toggle (Figma 51×31, track #65C466 on / #E9E9EA off).
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

    // Edit/archive/delete moved off the (now-removed) 3-dot menu onto a
    // long-press, so the action set stays reachable without a visible trigger.
    if (menuActions.isEmpty) return card;
    return GestureDetector(
      onLongPress: () =>
          showCardActionMenu(context: context, actions: menuActions),
      child: card,
    );
  }
}
