import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Guest-gate modal (Figma "Loadme New" 7102:15795). Shown when a guest tries
// to perform an action that needs an account — e.g. tapping "Bog'lanish" on a
// load / transport detail, or any authed-only bottom-nav destination.
//
// Centered dialog: an elevated blue "log in" glyph, a single title line, and a
// "Hozir emas" (dismiss) / "Ha, kiraman" (→ /auth/welcome) button pair.
Future<void> showMobileAuthRequiredSheet(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => const _AuthRequiredModal(),
  );
}

class _AuthRequiredModal extends StatelessWidget {
  const _AuthRequiredModal();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Elevated white disc with the blue "log in" glyph.
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: c.surface,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14101828),
                      offset: Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(LucideIcons.logIn, size: 28, color: c.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Ilovadan to‘liq foydalanish uchun tizimga kirishingiz zarur',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 22 / 16,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _ModalButton(
                      label: 'Hozir emas',
                      filled: false,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ModalButton(
                      label: 'Ha, kiraman',
                      filled: true,
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/auth/welcome');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModalButton extends StatelessWidget {
  const _ModalButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: filled ? c.primary : c.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: filled
              ? null
              : BoxDecoration(
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(12),
                ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: filled ? Colors.white : c.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
