import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';

// Shared building blocks for the Figma `Add load` form. All inputs have:
//   - 14/500 label with optional red `*` for required
//   - 44px height, white surface, 8px radius, subtle border
//   - Trailing icon (chevron/location/calendar)

class AddLoadLabel extends StatelessWidget {
  const AddLoadLabel({super.key, required this.text, this.required = false});
  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.types;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: t.bodyMedium.copyWith(color: c.textPrimary),
          children: [
            TextSpan(text: text),
            if (required) TextSpan(text: ' *', style: TextStyle(color: c.error)),
          ],
        ),
      ),
    );
  }
}

class AddLoadField extends StatelessWidget {
  const AddLoadField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.suffix,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.types;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              // `isDense: true` shrinks the InputDecorator; combined with
              // textAlignVertical.center the hint sits on the exact same
              // baseline as the `Text` placeholder used in `AddLoadSelectTile`.
              textAlignVertical: TextAlignVertical.center,
              style: t.body.copyWith(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: t.body.copyWith(color: c.textMuted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          if (suffix != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: suffix,
            ),
        ],
      ),
    );
  }
}

class AddLoadSelectTile extends StatelessWidget {
  const AddLoadSelectTile({
    super.key,
    required this.hintText,
    required this.value,
    required this.onTap,
    this.icon = Icons.keyboard_arrow_down_rounded,
  });

  final String hintText;
  final String? value;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.types;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? hintText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: value == null
                    ? t.body.copyWith(color: c.textMuted)
                    : t.body.copyWith(color: c.textPrimary),
              ),
            ),
            Icon(icon, color: c.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class AddLoadInputWithUnit extends StatelessWidget {
  const AddLoadInputWithUnit({
    super.key,
    required this.controller,
    required this.hintText,
    required this.unit,
    required this.onUnitTap,
  });

  final TextEditingController controller;
  final String hintText;
  final String unit;
  final VoidCallback onUnitTap;

  // Per Figma: unit pill is a fixed-width slot on the right so the divider
  // line sits at the same X-coordinate for USD / m³ / tons. Without this, the
  // pill grows/shrinks with the label and the dividers wander.
  static const double _unitSlotWidth = 78;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.types;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlignVertical: TextAlignVertical.center,
              style: t.body.copyWith(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: t.body.copyWith(color: c.textMuted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          SizedBox(
            width: _unitSlotWidth,
            child: InkWell(
              onTap: onUnitTap,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Divider — fixed position relative to right edge.
                  Container(width: 1, height: 24, color: c.border),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      unit,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.body.copyWith(color: c.textPrimary),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: c.textMuted,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
