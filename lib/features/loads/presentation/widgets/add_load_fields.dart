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
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                isDense: true,
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
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                isDense: true,
              ),
            ),
          ),
          InkWell(
            onTap: onUnitTap,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
              child: Row(
                children: [
                  Container(
                    width: 1,
                    height: 24,
                    color: c.border,
                    margin: const EdgeInsets.only(right: 8),
                  ),
                  Text(unit, style: t.body.copyWith(color: c.textPrimary)),
                  Icon(Icons.keyboard_arrow_down_rounded, color: c.textMuted, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
