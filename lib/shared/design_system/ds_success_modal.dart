import 'dart:math';

import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';

// Mirrors the Figma `success modal` (centered dialog, blue check icon with
// concentric pulse rings, body, full-width CTA, X close in top-right).
Future<void> showDsSuccessModal(
  BuildContext context, {
  required String title,
  required String message,
  required String actionLabel,
  required VoidCallback onAction,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (ctx) => DsSuccessModal(
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: () {
        Navigator.pop(ctx);
        onAction();
      },
    ),
  );
}

class DsSuccessModal extends StatelessWidget {
  const DsSuccessModal({
    super.key,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.types;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _DashedRing(size: 64, color: c.primary.withValues(alpha: 0.2)),
                        _DashedRing(size: 50, color: c.primary.withValues(alpha: 0.35)),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: c.primary50, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Icon(Icons.check_rounded, color: c.primary, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  InkResponse(
                    onTap: () => Navigator.pop(context),
                    radius: 22,
                    child: Icon(Icons.close_rounded, color: c.textMuted, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(title, style: t.h2),
              const SizedBox(height: 6),
              Text(message, style: t.body.copyWith(color: c.textSecondary, height: 22 / 14)),
              const SizedBox(height: 20),
              DsButton(label: actionLabel, onPressed: onAction),
            ],
          ),
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
      ..strokeWidth = 1.5;
    final r = size.shortestSide / 2;
    final center = Offset(size.width / 2, size.height / 2);
    const dashes = 26;
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
