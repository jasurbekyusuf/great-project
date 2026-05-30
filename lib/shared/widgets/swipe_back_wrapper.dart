import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Mirrors web `SwipeBackWrapper`: lets the user swipe from the left edge to
// pop. Wrap any screen body with this widget when iOS-like back gesture is
// expected (Android default lacks it for go_router push).
class SwipeBackWrapper extends StatelessWidget {
  const SwipeBackWrapper({
    super.key,
    required this.child,
    this.enabled = true,
    this.onBack,
    this.edgeWidth = 24,
    this.minDistance = 60,
  });

  final Widget child;
  final bool enabled;
  final VoidCallback? onBack;
  final double edgeWidth;
  final double minDistance;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    double startDx = 0;
    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: edgeWidth,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (d) => startDx = d.globalPosition.dx,
            onHorizontalDragEnd: (d) {
              final delta = (d.velocity.pixelsPerSecond.dx > 0)
                  ? (d.velocity.pixelsPerSecond.dx / 4)
                  : 0;
              if (delta >= minDistance || (d.primaryVelocity ?? 0) > 350) {
                _back(context);
              }
              startDx = 0;
            },
            onHorizontalDragUpdate: (d) {
              if (d.globalPosition.dx - startDx >= minDistance) {
                _back(context);
                startDx = double.infinity;
              }
            },
          ),
        ),
      ],
    );
  }

  void _back(BuildContext context) {
    if (onBack != null) {
      onBack!();
      return;
    }
    if (context.canPop()) context.pop();
  }
}
