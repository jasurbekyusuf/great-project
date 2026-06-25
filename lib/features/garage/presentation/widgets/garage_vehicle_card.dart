import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/shared/widgets/load_card_parts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Figma "Transportlar" vehicle card (node 6593-19490, frame 2087329820):
/// a 319×208 photo (r16) with the licence plate bottom-left and a round edit
/// button bottom-right, then a type chip + model row underneath.
class GarageVehicleCard extends StatelessWidget {
  const GarageVehicleCard({
    super.key,
    required this.name,
    required this.model,
    required this.plate,
    required this.onEdit,
    this.photoUrl,
    this.onTap,
  });

  final String name;
  final String model;
  final String plate;
  final VoidCallback onEdit;
  final String? photoUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FigmaCardShell(
      onTap: onTap ?? () {},
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo + plate + edit overlay (Figma 319×208, r16).
          AspectRatio(
            aspectRatio: 319 / 208,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _VehiclePhoto(url: photoUrl),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: _LicensePlate(plate: plate),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: _EditButton(onTap: onEdit),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Type chip + model.
          Row(
            children: [
              VehicleTypeChip(label: name),
              const Spacer(),
              Text(
                model,
                style: const TextStyle(
                  fontSize: 12,
                  height: 18 / 12,
                  fontWeight: FontWeight.w500,
                  color: FigmaPalette.label,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VehiclePhoto extends StatelessWidget {
  const _VehiclePhoto({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url != null) {
      return Image.network(url!, fit: BoxFit.cover);
    }
    return const ColoredBox(
      color: FigmaPalette.avatarBg,
      child: Center(
        child: Icon(LucideIcons.truck, size: 48, color: FigmaPalette.muted),
      ),
    );
  }
}


class _EditButton extends StatelessWidget {
  const _EditButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shadowColor: FigmaPalette.cardShadow,
      child: InkWell(
        onTap: onTap,
        child: const SizedBox(
          width: 28,
          height: 28,
          child: Icon(LucideIcons.pencil, size: 14, color: FigmaPalette.ink),
        ),
      ),
    );
  }
}

/// Compact Uzbek licence plate (white field, black frame, blue "UZ" strip).
class _LicensePlate extends StatelessWidget {
  const _LicensePlate({required this.plate});
  final String plate;

  @override
  Widget build(BuildContext context) {
    // "30 A 701 AS" → region "30", number "A 701 AS".
    final trimmed = plate.trim();
    final space = trimmed.indexOf(' ');
    final region = space == -1 ? trimmed : trimmed.substring(0, space);
    final number = space == -1 ? '' : trimmed.substring(space + 1);

    // The region ("30") reads smaller than the plate number (Figma 6593:19490:
    // region 15.75 vs number 22.75 — kept proportional here).
    const regionStyle = TextStyle(
      fontSize: 13,
      height: 1,
      fontWeight: FontWeight.w700,
      color: FigmaPalette.ink,
    );
    const numberStyle = TextStyle(
      fontSize: 18,
      height: 1,
      fontWeight: FontWeight.w700,
      color: FigmaPalette.ink,
      letterSpacing: 0.5,
    );

    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: FigmaPalette.ink, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(region, style: regionStyle),
          ),
          Container(width: 1, color: FigmaPalette.ink),
          // Number + UZ flag strip share one cell — no divider between them.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(number, style: numberStyle),
                const SizedBox(width: 4),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _flagBar(),
                    const SizedBox(height: 1),
                    const Text(
                      'UZ',
                      style: TextStyle(
                        fontSize: 7,
                        height: 1,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1271A1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _flagBar() => ClipRRect(
        borderRadius: BorderRadius.circular(1),
        child: Column(
          children: const [
            SizedBox(width: 12, height: 2, child: ColoredBox(color: Color(0xFF338AF3))),
            SizedBox(width: 12, height: 2, child: ColoredBox(color: Color(0xFFF0F0F0))),
            SizedBox(width: 12, height: 2, child: ColoredBox(color: Color(0xFF1F9736))),
          ],
        ),
      );
}
