import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Pixel-faithful port of the "New design (READY)" empty state used on the
/// Garaj › Transportlar (node 6782:10897) and Mening yuklarim (node
/// 6806:15034) screens.
///
/// Figma stack (centred):
///   illustration (core 199×168) → [gap] → message (Inter 14/18 #576075,
///   centred) → 40 → button (225×48, #004EEB, r8).
///
/// The exported illustration PNG is 231×200: the 199×168 core art plus a soft
/// drop-shadow halo (margins L17 / T12 / R15 / B20). We reserve only the
/// 199×168 core for layout and let the halo overflow, so the gap below is
/// measured from the core exactly like Figma.
class DsIllustrationEmpty extends StatelessWidget {
  const DsIllustrationEmpty({
    super.key,
    required this.asset,
    required this.message,
    this.gap = 16,
    this.actionLabel,
    this.onAction,
    this.haloSize = const Size(231, 200),
    this.haloOffset = const Offset(-17, -12),
  });

  /// Illustration asset (231×200 PNG, 199×168 core + shadow halo).
  final String asset;

  /// Centred message under the illustration.
  final String message;

  /// Illustration → message gap. Figma: 16 on Transportlar, 8 on Mening
  /// yuklarim.
  final double gap;

  /// Primary "Qo'shish" action. Both must be set for the button to render.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// The exported PNG's full size (199×168 core + soft drop-shadow halo) and
  /// the offset that re-aligns that core onto the reserved 199×168 box. The
  /// default fits the Garaj / Mening yuklarim art; the Xabarlar art is taller.
  final Size haloSize;
  final Offset haloOffset;

  // Illustration core (logical px) — constant across the empty-state arts.
  static const double _coreW = 199;
  static const double _coreH = 168;

  @override
  Widget build(BuildContext context) {
    final hasAction = actionLabel != null && onAction != null;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _coreW,
            height: _coreH,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: haloOffset.dx,
                  top: haloOffset.dy,
                  child: Image.asset(
                    asset,
                    width: haloSize.width,
                    height: haloSize.height,
                    fit: BoxFit.fill,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: gap),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 18 / 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF576075),
              ),
            ),
          ),
          if (hasAction) ...[
            const SizedBox(height: 40),
            _AddButton(label: actionLabel!, onTap: onAction!),
          ],
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Figma `Buttons` (225×48): #004EEB, r8, fixed width, content centred —
    // plus icon (20, 1.5 stroke) + 8 gap + label (Inter 14/20 w600 #FFFFFF).
    return SizedBox(
      width: 225,
      height: 48,
      child: Material(
        color: FigmaPalette.primary,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.plus, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
