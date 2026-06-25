import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Figma "Login" splash (Authorization → 6937:25297): a plain white screen with
/// the LoadMe logo lockup (181×128) centered, shown briefly before onboarding.
class AuthSplashScreen extends StatefulWidget {
  const AuthSplashScreen({super.key});

  @override
  State<AuthSplashScreen> createState() => _AuthSplashScreenState();
}

class _AuthSplashScreenState extends State<AuthSplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) context.go('/auth/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: 181,
          height: 128,
          child: Image.asset(
            'assets/images/loadme_splash_logo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
