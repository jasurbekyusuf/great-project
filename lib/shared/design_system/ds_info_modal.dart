import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Single-button informational modal (Figma "gate" dialog): a white circular
/// icon badge, a bold centred title, a grey supporting line and a full-width
/// blue "Tushunarli" button. Used when an action isn't available yet — e.g.
/// rating / reporting a contact you haven't worked with.
Future<void> showDsInfoModal(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  String buttonText = 'Tushunarli',
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.40),
    builder: (ctx) => _DsInfoModal(
      icon: icon,
      title: title,
      message: message,
      buttonText: buttonText,
    ),
  );
}

/// The two "contact gate" variants surfaced from the owner / carrier card
/// Baholash (rate) and Shikoyat qilish (report) chips. Centralising the copy
/// keeps the load-detail and transport-detail screens byte-for-byte identical.
enum DsContactGate { rate, report }

/// Shows the rate / report gate modal for [kind] (same dialog on both the load
/// and transport detail screens).
Future<void> showContactGateModal(BuildContext context, DsContactGate kind) {
  switch (kind) {
    case DsContactGate.rate:
      return showDsInfoModal(
        context,
        icon: LucideIcons.star,
        title: "Hozircha baho qo'ya olmaysiz",
        message: 'Bu foydalanuvchini u bilan hamkorlik qilganingizdan keyin '
            'baholashingiz mumkin bo‘ladi.',
      );
    case DsContactGate.report:
      return showDsInfoModal(
        context,
        icon: LucideIcons.flag,
        title: 'Hozircha shikoyat qila olmaysiz',
        message: 'Bu foydalanuvchi ustidan u bilan hamkorlik qilganingizdan '
            'keyin shikoyat qilishingiz mumkin bo‘ladi.',
      );
  }
}

class _DsInfoModal extends StatelessWidget {
  const _DsInfoModal({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonText,
  });

  final IconData icon;
  final String title;
  final String message;
  final String buttonText;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      backgroundColor: FigmaPalette.pageBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // White circle badge, soft shadow, primary-blue glyph.
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0F000000),
                    offset: Offset(0, 2),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Icon(icon, size: 24, color: FigmaPalette.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                height: 22 / 16,
                fontWeight: FontWeight.w600,
                color: FigmaPalette.inkStrong,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 18 / 13,
                fontWeight: FontWeight.w500,
                color: FigmaPalette.gray700,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: FigmaPalette.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D101828),
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      child: Text(
                        buttonText,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
