import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Figma auth language pill ("Keling boshlaymiz!" — Authorization).
/// Light-gray r10 chip: translate glyph · language label · chevron-down.
class MobileLanguagePill extends StatelessWidget {
  const MobileLanguagePill({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: FigmaPalette.chipBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.languages,
                size: 20, color: FigmaPalette.countLabel),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w400,
                color: FigmaPalette.countLabel,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(LucideIcons.chevronDown,
                size: 20, color: FigmaPalette.countLabel),
          ],
        ),
      ),
    );
  }
}
