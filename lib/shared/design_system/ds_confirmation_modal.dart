import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';

// Mirrors web `ConfirmationModal` (src/components/ConfirmationModal/index.tsx).
// Intent-driven palette + 2-button (confirm/cancel) bottom layout.
enum DsConfirmIntent { primary, danger, success, warning, info, logout, delete }

class _IntentPalette {
  const _IntentPalette({required this.bg, required this.bgHover, required this.iconColor, required this.iconBg});
  final Color bg;
  final Color bgHover;
  final Color iconColor;
  final Color iconBg;
}

Future<bool> showDsConfirmation(
  BuildContext context, {
  String? title,
  String? message,
  String? confirmText,
  String? cancelText,
  DsConfirmIntent intent = DsConfirmIntent.primary,
  IconData? icon,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => DsConfirmationModal(
      title: title ?? 'Подтверждение',
      message: message ?? 'Вы уверены, что хотите продолжить?',
      confirmText: confirmText ?? 'Подтвердить',
      cancelText: cancelText,
      intent: intent,
      icon: icon,
    ),
  );
  return result ?? false;
}

class DsConfirmationModal extends StatelessWidget {
  const DsConfirmationModal({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    this.cancelText,
    this.intent = DsConfirmIntent.primary,
    this.icon,
    this.loading = false,
  });

  final String title;
  final String message;
  final String confirmText;
  final String? cancelText;
  final DsConfirmIntent intent;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.space;
    final t = context.types;

    final palette = _palette(c, intent);
    final hasCancel = cancelText != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: palette.iconBg, shape: BoxShape.circle),
                  child: Icon(icon, color: palette.iconColor, size: 22),
                ),
              if (icon != null) SizedBox(height: s.md),
              Text(title, style: t.h2),
              const SizedBox(height: 4),
              Text(message, style: t.body.copyWith(color: c.textSecondary, height: 22 / 14)),
              SizedBox(height: s.lg),
              if (hasCancel)
                Row(
                  children: [
                    Expanded(child: _ConfirmButton(label: confirmText, palette: palette, loading: loading, onTap: () => Navigator.pop(context, true))),
                    SizedBox(width: s.sm),
                    Expanded(child: _CancelButton(label: cancelText!, onTap: () => Navigator.pop(context, false))),
                  ],
                )
              else
                SizedBox(width: double.infinity, child: _ConfirmButton(label: confirmText, palette: palette, loading: loading, onTap: () => Navigator.pop(context, true))),
            ],
          ),
        ),
      ),
    );
  }

  _IntentPalette _palette(dynamic c, DsConfirmIntent intent) {
    switch (intent) {
      case DsConfirmIntent.primary:
      case DsConfirmIntent.info:
        return _IntentPalette(bg: c.primary, bgHover: c.primaryHover, iconColor: c.primary, iconBg: c.primary50);
      case DsConfirmIntent.danger:
      case DsConfirmIntent.delete:
      case DsConfirmIntent.logout:
        return _IntentPalette(bg: c.error, bgHover: c.red700, iconColor: c.error, iconBg: c.red50);
      case DsConfirmIntent.success:
        return _IntentPalette(bg: c.success, bgHover: c.green700, iconColor: c.success, iconBg: c.primary50);
      case DsConfirmIntent.warning:
        return _IntentPalette(bg: c.warning, bgHover: c.yellow700, iconColor: c.warning, iconBg: c.yellow100);
    }
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.label, required this.palette, required this.loading, required this.onTap});
  final String label;
  final _IntentPalette palette;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: loading ? null : onTap,
        child: SizedBox(
          height: 48,
          child: Center(
            child: loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(label, style: context.types.button.copyWith(color: Colors.white, fontSize: 16, height: 24 / 16)),
          ),
        ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label, style: context.types.button.copyWith(color: c.textPrimary, fontSize: 16, height: 24 / 16)),
        ),
      ),
    );
  }
}
