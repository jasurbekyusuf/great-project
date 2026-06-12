import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// White rounded page header shared by the redesigned screens (Magnit, Garaj,
/// Transport detail). Shows a back chevron only when the route can pop, a
/// centred title, an optional [trailing] action, and an optional [bottom]
/// widget (e.g. a segmented tab control) below the title row.
class FrostedHeader extends StatelessWidget {
  const FrostedHeader({
    super.key,
    required this.title,
    this.trailing,
    this.bottom,
  });

  final String title;
  final Widget? trailing;
  final Widget? bottom;

  static const _shadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 2)),
  ];

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: _shadow,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: canPop
                          ? InkResponse(
                              onTap: () => Navigator.maybePop(context),
                              radius: 20,
                              child: const Icon(LucideIcons.chevronLeft,
                                  size: 24, color: FigmaPalette.ink),
                            )
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 24 / 16,
                          fontWeight: FontWeight.w600,
                          color: FigmaPalette.ink,
                        ),
                      ),
                    ),
                    SizedBox(width: 24, child: trailing),
                  ],
                ),
              ),
            ),
            if (bottom != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: bottom,
              ),
          ],
        ),
      ),
    );
  }
}
