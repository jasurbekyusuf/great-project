import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';

class AuthStepDots extends StatelessWidget {
  const AuthStepDots({super.key, required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final active = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: EdgeInsets.symmetric(horizontal: context.space.xs),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? context.colors.primary : context.colors.border,
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}
