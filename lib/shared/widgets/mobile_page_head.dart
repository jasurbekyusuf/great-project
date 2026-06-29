import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';

// Mirrors `client_frontend_web-master/src/components/PageHead/styles.module.scss`:
// min-height: 52px, border-bottom 1px, border-bottom-radius: 24px, sticky.
class MobilePageHead extends StatelessWidget {
  const MobilePageHead({
    super.key,
    required this.title,
    this.trailing,
    this.leading,
    this.onBack,
    this.showBack = true,
  });

  final String title;
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.space;
    final t = context.types;

    return Container(
      // Figma redesign page head (e.g. "Xabarlar" 6804:11446): a white card
      // (fill is white-glass over the gray page) with 24px bottom corners and a
      // soft drop shadow — #000 @ 8%, y2, blur 14 — NOT a 1px hairline border.
      // The shadow + white-on-gray contrast is what makes the rounded bottom
      // corners read as a floating bar.
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(s.radiusXl),
          bottomRight: Radius.circular(s.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 2),
            blurRadius: 14,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: s.pageHeadHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  // Only consult the IMMEDIATE Navigator. go_router 14's
                  // `context.canPop()` walks every branch's navigator and
                  // returns true if *any* of them has a pushed route — which
                  // makes the back arrow show up on unrelated tab roots.
                  // Same reason we call `Navigator.maybePop` directly: routing
                  // through `context.pop()` here can pop a different branch.
                  child: leading ??
                      ((showBack &&
                              (onBack != null ||
                                  (Navigator.maybeOf(context)?.canPop() ?? false)))
                          ? InkResponse(
                              onTap: onBack ??
                                  () => Navigator.maybePop(context),
                              radius: 20,
                              // Figma redesign back control is a Lucide
                              // chevron-left, 24x24, #101828 (e.g. "Xabarlar"
                              // 6804:11446) — not the Material iOS arrow.
                              child: Icon(LucideIcons.chevronLeft, size: 24, color: c.textPrimary),
                            )
                          : null),
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    // Figma redesign page-head title (e.g. "Xabarlar"
                    // 6804:11446, "Yuk ma'lumotlari" 6435:39895): Inter 16/24
                    // SemiBold #101828. h3 (18/26) runs 2px large, so override
                    // size/height only — keeping h3's Inter face, w600 and color.
                    style: t.h3.copyWith(fontSize: 16, height: 24 / 16),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 32),
                  child: trailing,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
