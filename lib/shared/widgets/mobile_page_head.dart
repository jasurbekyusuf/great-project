import 'package:flutter/material.dart';
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
      decoration: BoxDecoration(
        color: c.background,
        border: Border(bottom: BorderSide(color: c.borderSubtle, width: 1)),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(s.radiusXl),
          bottomRight: Radius.circular(s.radiusXl),
        ),
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
                              child: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: c.textPrimary),
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
                    style: t.h3,
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
