import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';

/// Shared building blocks for the Figma load / truck cards and the load
/// details screen, so the three keep one implementation.

/// Formats a quantity without a trailing `.0` (e.g. 33 → "33", 5.5 → "5.5").
String formatQty(double v) =>
    v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

/// Rounded-16 card surface with the Figma drop-shadow (#101828 @4%, 0/2/8)
/// and an ink ripple — the shared shell for the load and truck list cards.
class FigmaCardShell extends StatelessWidget {
  const FigmaCardShell({
    super.key,
    required this.onTap,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  });

  final VoidCallback onTap;
  final Widget child;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: FigmaPalette.cardShadow,
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Vertical dotted connector drawn between the route markers. Occupies a fixed
/// [width]×[height] box (so it aligns the icon column with the text column) and
/// centres the dot group within it.
class DottedConnector extends StatelessWidget {
  const DottedConnector({
    super.key,
    required this.height,
    this.width = 16,
    this.color = FigmaPalette.muted,
  });

  final double height;
  final double width;
  final Color color;

  static const _dot = 2.0;
  static const _gap = 3.0;

  @override
  Widget build(BuildContext context) {
    final count = (height / (_dot + _gap)).floor().clamp(1, 100);
    return SizedBox(
      width: width,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          count,
          (i) => Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : _gap),
            child: Container(width: 1.5, height: _dot, color: color),
          ),
        ),
      ),
    );
  }
}

/// 1×12 vertical hairline used between footer stats.
class CardVDivider extends StatelessWidget {
  const CardVDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 12, color: FigmaPalette.divider);
}

/// "City COUNTRY" route line — bold city + muted country code.
class RouteCityRow extends StatelessWidget {
  const RouteCityRow({super.key, required this.city, required this.country});

  final String city;
  final String country;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            city,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
              color: FigmaPalette.inkStrong,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          country,
          style: const TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w500,
            color: FigmaPalette.label,
          ),
        ),
      ],
    );
  }
}

/// Footer stat: an icon (SVG or [Icon]) + 12/500 value text.
class RouteStatChip extends StatelessWidget {
  const RouteStatChip({
    super.key,
    required this.icon,
    required this.text,
    this.gap = 4,
    this.color = FigmaPalette.ink,
  });

  final Widget icon;
  final String text;
  final double gap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(width: gap),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            height: 18 / 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Coloured role pill — "Yuk egasi" reads as danger, others as blue.
class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final l = label.toLowerCase();
    final danger = l.contains('egasi') || l.contains('shipper');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: danger ? FigmaPalette.dangerBg : FigmaPalette.roleBlueBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          height: 18 / 12,
          fontWeight: FontWeight.w500,
          color: danger ? FigmaPalette.dangerText : FigmaPalette.primary,
        ),
      ),
    );
  }
}
