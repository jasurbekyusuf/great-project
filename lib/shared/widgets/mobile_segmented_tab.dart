import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';

enum MobileSegmentedTabVariant {
  // Web default: white pill on light track (Profile, Saved, etc.).
  light,
  // Loads/Trucks switcher: white pill on dark track, blue active (web LoadsV2).
  primaryFilled,
}

class MobileSegmentedTab extends StatelessWidget {
  const MobileSegmentedTab({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    this.variant = MobileSegmentedTabVariant.light,
    this.height,
  });

  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final MobileSegmentedTabVariant variant;

  /// Track height override. Defaults to the design-system `tabsHeight` (40).
  /// The Figma "Xabarlar" segmented control is 36 tall (thumb 32), so the
  /// notifications screen passes 36 to sit 1:1 with that frame.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.space;
    final t = context.types;

    final isPrimary = variant == MobileSegmentedTabVariant.primaryFilled;
    // Track uses theme-aware `tabsTrack` for both variants (light gray in
    // light mode, dark navy in dark mode). Only the thumb color changes.
    final trackColor = c.tabsTrack;
    final thumbColor = isPrimary ? c.primary : c.tabsThumb;
    // Figma: track r12 with 2px padding; the active thumb is r10 so its corner
    // sits concentric inside the track corner (10 = 12 − 2). With a 40px track
    // the thumb is 36px tall, matching the Figma active tab.
    const trackRadius = 12.0;
    const thumbInset = 2.0;
    const thumbRadius = 10.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final innerWidth = width - thumbInset * 2;
        final segmentWidth = innerWidth / items.length;

        return ClipRRect(
          borderRadius: BorderRadius.circular(trackRadius),
          child: Container(
            width: width,
            height: height ?? s.tabsHeight,
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius: BorderRadius.circular(trackRadius),
            ),
            padding: const EdgeInsets.all(thumbInset),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  left: segmentWidth * selectedIndex,
                  top: 0,
                  bottom: 0,
                  width: segmentWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: thumbColor,
                      borderRadius: BorderRadius.circular(thumbRadius),
                      border: isPrimary
                          ? null
                          : Border.all(
                              color: Colors.black.withValues(alpha: 0.08),
                              width: 0.5),
                      boxShadow: isPrimary
                          ? [
                              BoxShadow(
                                color: c.primary.withValues(alpha: 0.30),
                                offset: const Offset(0, 4),
                                blurRadius: 12,
                                spreadRadius: -2,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                offset: const Offset(0, 4),
                                blurRadius: 4,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                offset: Offset.zero,
                                blurRadius: 2,
                              ),
                            ],
                    ),
                  ),
                ),
                Row(
                  children: List.generate(items.length, (index) {
                    final active = index == selectedIndex;
                    // primaryFilled: active = white (on blue), inactive = textPrimary (dark in light mode, light in dark mode).
                    // light variant: text is always primary (works on light track).
                    final color = isPrimary
                        ? (active ? Colors.white : c.textPrimary)
                        : c.textPrimary;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(index),
                        child: Center(
                          child: Text(items[index],
                              style: t.bodyMedium.copyWith(color: color)),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
