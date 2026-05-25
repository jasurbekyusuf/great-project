import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/auth/presentation/widgets/auth_shell.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';
import 'package:loadme_mobile/shared/design_system/ds_input.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController(text: '+998');

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      showBack: true,
      onBack: () => context.pop(),
      title: 'Forgot password',
      subtitle: 'Enter your phone and we will send a reset code',
      child: Column(
        children: [
          DsInput(controller: _phoneController, label: 'Phone number', keyboardType: TextInputType.phone),
          SizedBox(height: context.space.lg),
          DsButton(label: 'Send code', onPressed: () => context.go('/auth/verify')),
        ],
      ),
    );
  }
}
