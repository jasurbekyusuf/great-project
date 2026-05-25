import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';

class DsButton extends StatelessWidget {
  const DsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.height = 48,
    this.radius,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final double height;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: context.colors.primary,
          disabledBackgroundColor: const Color(0xFF89AEEF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius ?? context.space.radiusMd),
          ),
        ),
        child: loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(label),
      ),
    );
  }
}
