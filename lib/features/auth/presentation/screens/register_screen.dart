import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:loadme_mobile/features/auth/presentation/providers/auth_flow_provider.dart';
import 'package:loadme_mobile/features/auth/presentation/widgets/auth_shell.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';
import 'package:loadme_mobile/shared/design_system/ds_input.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  bool _terms = false;
  bool _loading = false;

  Future<void> _register() async {
    final flow = ref.read(authFlowProvider);
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).register(
            fullName: _nameController.text.trim(),
            companyName: _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
            phone: flow.phone,
            smsId: flow.smsId,
            otp: flow.otp,
          );
      if (mounted) context.go('/loads');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      showBack: true,
      onBack: () => context.pop(),
      title: 'Create account',
      subtitle: 'Complete your registration',
      child: Column(
        children: [
          DsInput(controller: _nameController, label: 'Full name'),
          SizedBox(height: context.space.md),
          DsInput(controller: _companyController, label: 'Company name (optional)'),
          SizedBox(height: context.space.md),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _terms,
            onChanged: (v) => setState(() => _terms = v ?? false),
            title: const Text('I agree to terms and privacy policy'),
          ),
          SizedBox(height: context.space.lg),
          DsButton(label: 'Register', onPressed: _terms ? _register : null, loading: _loading),
        ],
      ),
    );
  }
}
