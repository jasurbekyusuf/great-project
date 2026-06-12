import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Empty-state placeholder.
///
/// Plain (legacy) mode = just [title] (+ optional [subtitle]).
/// Rich mode (Figma `Transportlar` empty, node 6542:41936) kicks in when an
/// [icon] and/or a primary action ([actionLabel] + [onAction]) is supplied:
/// centered illustration, muted message, and a blue "Qo'shish" button.
class DsEmptyState extends StatelessWidget {
  const DsEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;

  /// Optional illustration shown above the message (e.g. the crossed-out truck).
  final Widget? icon;

  /// Primary action button (label + handler). Both must be set to render it.
  final String? actionLabel;
  final VoidCallback? onAction;

  // Figma empty-state message colour (gray/600-ish), distinct from the tokens.
  static const _message = Color(0xFF576075);

  @override
  Widget build(BuildContext context) {
    final hasAction = actionLabel != null && onAction != null;
    if (icon == null && !hasAction) {
      // Legacy text-only placeholder.
      return Center(
        child: Padding(
          padding: EdgeInsets.all(context.space.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              if (subtitle != null) ...[
                SizedBox(height: context.space.sm),
                Text(subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon!, const SizedBox(height: 16)],
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 18 / 14,
                fontWeight: FontWeight.w500,
                color: _message,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  height: 18 / 12,
                  fontWeight: FontWeight.w500,
                  color: FigmaPalette.muted,
                ),
              ),
            ],
            if (hasAction) ...[
              const SizedBox(height: 40),
              _AddButton(label: actionLabel!, onTap: onAction!),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Figma `Buttons` (6542:41953): #004EEB, r8, plus + label, pad 32/10/36/12.
    return Material(
      color: FigmaPalette.primary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 10, 36, 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.plus, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
