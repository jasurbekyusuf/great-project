import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/app_color_tokens.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';

enum DsButtonVariant { solid, outline, secondary, ghost, edit, remove, report }

enum DsButtonSize { md, sm }

// Mirrors web `Buttons/PrimaryButton.jsx` and the Chakra button variants used
// throughout `src/modules`. Default = 44px height, 8px radius, 14/600 label.
class DsButton extends StatelessWidget {
  const DsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = DsButtonVariant.solid,
    this.size = DsButtonSize.md,
    this.loading = false,
    this.icon,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final DsButtonVariant variant;
  final DsButtonSize size;
  final bool loading;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.space;
    final t = context.types;

    final height = size == DsButtonSize.md ? s.controlHeight : s.controlHeightSm;
    final disabled = onPressed == null || loading;

    final palette = _palette(c, variant, disabled: disabled);

    final child = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: palette.fg),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: palette.fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: t.button.copyWith(color: palette.fg),
                ),
              ),
            ],
          );

    final btn = Material(
      color: palette.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(s.radiusSm),
        side: palette.border == null ? BorderSide.none : BorderSide(color: palette.border!),
      ),
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: BorderRadius.circular(s.radiusSm),
        splashColor: palette.fg.withValues(alpha: 0.08),
        highlightColor: palette.fg.withValues(alpha: 0.04),
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: child),
          ),
        ),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: btn);
    }
    return btn;
  }

  _Palette _palette(AppColorTokens c, DsButtonVariant v, {required bool disabled}) {
    switch (v) {
      case DsButtonVariant.solid:
        return _Palette(
          bg: disabled ? c.primaryDisabled : c.primary,
          fg: Colors.white,
        );
      case DsButtonVariant.outline:
        return _Palette(
          bg: Colors.transparent,
          fg: disabled ? c.primaryDisabled : c.primary,
          border: disabled ? c.primaryDisabled : c.primary,
        );
      case DsButtonVariant.secondary:
        return _Palette(
          bg: c.primary50,
          fg: disabled ? c.primaryDisabled : c.primary,
        );
      case DsButtonVariant.ghost:
        return _Palette(
          bg: Colors.transparent,
          fg: disabled ? c.textMuted : c.textPrimary,
        );
      case DsButtonVariant.edit:
        return _Palette(
          bg: c.gray100,
          fg: c.textPrimary,
          border: c.border,
        );
      case DsButtonVariant.remove:
        return _Palette(
          bg: c.red50,
          fg: c.error,
          border: c.red200,
        );
      case DsButtonVariant.report:
        return _Palette(
          bg: Colors.transparent,
          fg: c.error,
          border: c.red200,
        );
    }
  }
}

class _Palette {
  const _Palette({required this.bg, required this.fg, this.border});
  final Color bg;
  final Color fg;
  final Color? border;
}
