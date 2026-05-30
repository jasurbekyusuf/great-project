import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';

// Mirrors typical web card: white surface, 16px radius, subtle border, 16px padding.
class DsCard extends StatelessWidget {
  const DsCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderColor,
    this.background,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.space;
    final radius = BorderRadius.circular(s.radiusLg);

    final container = Container(
      padding: padding ?? EdgeInsets.all(s.lg),
      decoration: BoxDecoration(
        color: background ?? c.surface,
        borderRadius: radius,
        border: Border.all(color: borderColor ?? c.borderSubtle, width: 1),
      ),
      child: child,
    );

    if (onTap == null) return container;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: container,
      ),
    );
  }
}
