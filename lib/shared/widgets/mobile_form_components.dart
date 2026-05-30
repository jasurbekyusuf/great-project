import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';

class MobileFormSection extends StatelessWidget {
  const MobileFormSection({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.space.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(context.space.radiusLg),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (subtitle != null) ...[
            SizedBox(height: context.space.xs),
            Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
          ],
          SizedBox(height: context.space.md),
          ...children,
        ],
      ),
    );
  }
}

class MobileFormField extends StatelessWidget {
  const MobileFormField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.maxLines = 1,
    this.suffixText,
    this.required = false,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? suffixText;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: Theme.of(context).textTheme.titleMedium,
            children: [
              if (required)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: context.colors.error),
                ),
            ],
          ),
        ),
        SizedBox(height: context.space.sm),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hintText,
            suffixText: suffixText,
            contentPadding: EdgeInsets.symmetric(
              horizontal: context.space.lg,
              vertical: context.space.md,
            ),
          ),
        ),
      ],
    );
  }
}

class MobileSelectTile extends StatelessWidget {
  const MobileSelectTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(context.space.radiusMd),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: context.space.lg, vertical: context.space.md),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(context.space.radiusMd),
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: context.colors.primary, size: 20),
              SizedBox(width: context.space.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
                  SizedBox(height: context.space.xs),
                  Text(value, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: context.colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class MobileChipGroup extends StatelessWidget {
  const MobileChipGroup({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  final List<String> items;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.space.sm,
      runSpacing: context.space.sm,
      children: items.map((item) {
        final active = item == selected;
        return ChoiceChip(
          selected: active,
          label: Text(item),
          labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: active
                    ? context.colors.primary
                    : context.colors.textPrimary,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
          selectedColor: context.colors.primary.withValues(alpha: 0.12),
          backgroundColor: context.colors.border.withValues(alpha: 0.45),
          side: BorderSide(
              color: active ? context.colors.primary : Colors.transparent),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.space.radiusSm)),
          onSelected: (_) => onChanged(item),
        );
      }).toList(),
    );
  }
}

class MobileUploadBox extends StatelessWidget {
  const MobileUploadBox(
      {super.key, required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.space.lg),
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: BorderRadius.circular(context.space.radiusMd),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(context.space.radiusMd),
            ),
            child:
                Icon(Icons.attach_file_rounded, color: context.colors.primary),
          ),
          SizedBox(width: context.space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: context.space.xs),
                Text(description,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MobileBottomSubmitBar extends StatelessWidget {
  const MobileBottomSubmitBar({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(context.space.lg, context.space.md,
            context.space.lg, context.space.lg),
        decoration: BoxDecoration(
          color: context.colors.background,
          border: Border(top: BorderSide(color: context.colors.border)),
        ),
        child: SizedBox(
          width: double.infinity,
          child: DsButton(
            label: label,
            loading: isLoading,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
