import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:loadme_mobile/features/auth/presentation/providers/auth_flow_provider.dart';
import 'package:loadme_mobile/features/auth/presentation/widgets/auth_shell.dart';
import 'package:loadme_mobile/features/auth/presentation/widgets/otp_code_field.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';

class PhoneVerificationScreen extends ConsumerStatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  ConsumerState<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends ConsumerState<PhoneVerificationScreen> {
  final _otpController = TextEditingController();
  int _seconds = 120;
  Timer? _timer;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds == 0) {
        timer.cancel();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final flow = ref.read(authFlowProvider);
    ref.read(authFlowProvider.notifier).setOtp(_otpController.text.trim());
    setState(() => _loading = true);
    final (session, fail) =
        await ref.read(authControllerProvider.notifier).verifyOtp(
              phone: flow.phone,
              smsId: flow.smsId,
              otp: _otpController.text.trim(),
              userFound: flow.userFound,
            );
    if (!mounted) return;
    setState(() => _loading = false);
    if (fail != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(fail.message)));
      return;
    }
    if (session != null) {
      context.go('/loads');
    } else {
      context.go('/auth/register');
    }
  }

  Future<void> _resend() async {
    final flow = ref.read(authFlowProvider);
    final (result, fail) =
        await ref.read(authControllerProvider.notifier).checkUserPhone(flow.phone);
    if (fail != null || result == null) return;
    ref.read(authFlowProvider.notifier).setPhoneCheckResult(
          phone: flow.phone,
          smsId: result.smsId,
          userFound: result.userFound,
        );
    setState(() => _seconds = 120);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds == 0) {
        timer.cancel();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(authFlowProvider);
    return AuthShell(
      showBack: true,
      onBack: () => context.pop(),
      title: 'Verification code',
      subtitle: 'We sent an SMS code to ${flow.phone}',
      child: Column(
        children: [
          OtpCodeField(controller: _otpController),
          SizedBox(height: context.space.md),
          Text(_seconds > 0 ? 'Resend in 00:${_seconds.toString().padLeft(2, '0')}' : 'Code expired'),
          SizedBox(height: context.space.md),
          if (_seconds == 0)
            TextButton(onPressed: _resend, child: const Text('Resend code')),
          SizedBox(height: context.space.lg),
          DsButton(label: 'Verify', onPressed: _submit, loading: _loading),
        ],
      ),
    );
  }
}
