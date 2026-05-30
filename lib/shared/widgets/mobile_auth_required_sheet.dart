import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';

// Mirrors `client_frontend_web-master/src/components/AuthRequiredModal/index.jsx`.
// Used when a guest tries to perform an authenticated action.
Future<void> showMobileAuthRequiredSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const _AuthRequiredSheet(),
  );
}

class _AuthRequiredSheet extends StatelessWidget {
  const _AuthRequiredSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.types;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(color: c.gray300, borderRadius: BorderRadius.circular(999)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _DashedRing(size: 96, color: c.red200),
                    _DashedRing(size: 80, color: c.red300),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: c.error, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: const Text(
                        '!',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 28),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Kirish kerak', style: t.h2),
            const SizedBox(height: 6),
            Text(
              'Bu amalni bajarish uchun avval tizimga kiring.',
              style: t.body.copyWith(color: c.textSecondary, height: 22 / 14),
            ),
            const SizedBox(height: 20),
            DsButton(
              label: 'Kirish',
              onPressed: () {
                Navigator.pop(context);
                context.go('/auth/welcome');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedRing extends StatelessWidget {
  const _DashedRing({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _DashedCirclePainter(color: color)),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final r = size.shortestSide / 2;
    final center = Offset(size.width / 2, size.height / 2);
    const dashes = 22;
    for (var i = 0; i < dashes; i++) {
      final startA = (2 * pi / dashes) * i;
      final sweepA = (2 * pi / dashes) * 0.5;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r - 1),
        startA,
        sweepA,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}
