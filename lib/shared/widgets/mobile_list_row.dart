import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';

// Generic mobile row used in Profile / Saved / Settings lists.
// Stack rows inside a `MobileListGroup` to get rounded outer corners (web parity).
class MobileListRow extends StatelessWidget {
  const MobileListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.leading,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.showChevron = true,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final bool showChevron;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.types;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: dense ? 14 : 20),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            if (leading == null && leadingIcon != null) ...[
              Icon(leadingIcon, size: 24, color: c.primary),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: t.bodyLgMedium.copyWith(color: titleColor ?? c.textPrimary),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: t.caption.copyWith(color: c.textSecondary)),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (trailing == null && showChevron)
              Icon(Icons.chevron_right_rounded, size: 20, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}

// Wraps a list of [MobileListRow] children with shared border, dividers between
// items, and 16px rounded outer corners. Mirrors web pattern in Profile.
class MobileListGroup extends StatelessWidget {
  const MobileListGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.space;

    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        items.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Divider(height: 1, thickness: 1, color: c.borderSubtle),
        ));
      }
      items.add(children[i]);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(s.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(s.radiusLg),
          border: Border.all(color: c.borderSubtle, width: 1),
        ),
        child: Column(children: items),
      ),
    );
  }
}
