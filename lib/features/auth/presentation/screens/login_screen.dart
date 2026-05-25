import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:loadme_mobile/features/auth/presentation/widgets/auth_shell.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';
import 'package:loadme_mobile/shared/design_system/ds_input.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (_, next) {
      if (next.value != null) context.go('/loads');
    });

    return AuthShell(
      showBack: true,
      onBack: () => context.go('/auth/welcome'),
      title: 'Sign in with password',
      subtitle: 'Use your phone and password',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DsInput(controller: _phoneController, label: 'Phone', keyboardType: TextInputType.phone),
          SizedBox(height: context.space.md),
          DsInput(controller: _passwordController, label: 'Password', obscureText: true),
          SizedBox(height: context.space.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: () => context.go('/auth/forgot-password'), child: const Text('Forgot password?')),
          ),
          SizedBox(height: context.space.md),
          DsButton(
            label: 'Sign in',
            loading: auth.isLoading,
            onPressed: () => ref.read(authControllerProvider.notifier).login(
                  _phoneController.text.trim(),
                  _passwordController.text,
                ),
          ),
          if (auth.hasError) ...[
            SizedBox(height: context.space.md),
            Text(auth.error.toString(), style: TextStyle(color: context.colors.error)),
          ],
        ],
      ),
    );
  }
}
