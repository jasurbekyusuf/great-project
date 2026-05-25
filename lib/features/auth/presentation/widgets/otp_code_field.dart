import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';

class OtpCodeField extends StatelessWidget {
  const OtpCodeField({super.key, required this.controller, this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      maxLength: 6,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineMedium,
      decoration: InputDecoration(
        counterText: '',
        hintText: '000000',
        contentPadding: EdgeInsets.symmetric(vertical: context.space.lg),
      ),
    );
  }
}
