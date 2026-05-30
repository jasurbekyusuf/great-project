import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';

// Mirrors `client_frontend_web-master/src/components/Tabs/Tabs.module.scss`:
// 40px height, bg #F2F3F5, white indicator with shadow, sliding animation.
class MobileSegmentedTab extends StatelessWidget {
  const MobileSegmentedTab({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.space;
    final t = context.types;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final segmentWidth = (width - 4) / items.length;

        return Container(
          width: width,
          height: s.tabsHeight,
          decoration: BoxDecoration(
            color: c.tabsTrack,
            borderRadius: BorderRadius.circular(s.radiusXs),
          ),
          padding: const EdgeInsets.all(2),
          child: Stack(
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
                    color: c.tabsThumb,
                    borderRadius: BorderRadius.circular(s.radiusXs),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 0.5),
                    boxShadow: [
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
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(index),
                      child: Center(
                        child: Text(
                          items[index],
                          style: t.bodyMedium.copyWith(color: c.textPrimary),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
