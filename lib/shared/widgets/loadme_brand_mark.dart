import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';

// LoadMe brand mark used in the top-left of Loads/Trucks screens.
// Loads the official PNG asset; falls back to a styled placeholder if the
// asset is missing (keeps the design intact in dev).
class LoadMeBrandMark extends StatelessWidget {
  const LoadMeBrandMark({super.key, this.size = 28, this.showWordmark = true, this.wordmarkColor});

  final double size;
  final bool showWordmark;
  final Color? wordmarkColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.types;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.28),
          child: Image.asset(
            'assets/images/loadme-logo.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: BorderRadius.circular(size * 0.28),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.local_shipping_rounded, color: Colors.white, size: size * 0.6),
            ),
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(width: 8),
          Text(
            'LoadMe',
            style: t.h3.copyWith(color: wordmarkColor ?? c.textPrimary, fontWeight: FontWeight.w700),
          ),
        ],
      ],
    );
  }
}
