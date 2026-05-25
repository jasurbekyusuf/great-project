import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/auth/presentation/widgets/auth_step_dots.dart';
import 'package:loadme_mobile/features/auth/presentation/widgets/auth_shell.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _index = 0;

  static const _pages = [
    ('Quick Cargo Search', 'Find loads and trucks fast with smart filters.'),
    ('Trusted Partners', 'Work with verified shippers, brokers, and carriers.'),
    ('All In One', 'Manage your logistics flow directly from your phone.'),
  ];

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Welcome to Loadme',
      subtitle: 'Your logistics workspace',
      child: Column(
        children: [
          SizedBox(
            height: 280,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (_, i) => Container(
                padding: EdgeInsets.all(context.space.lg),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(context.space.radiusLg),
                  border: Border.all(color: context.colors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.explore_outlined, size: 52, color: context.colors.primary),
                    SizedBox(height: context.space.md),
                    Text(_pages[i].$1, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                    SizedBox(height: context.space.sm),
                    Text(_pages[i].$2, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: context.space.lg),
          AuthStepDots(current: _index, total: _pages.length),
          SizedBox(height: context.space.xl),
          DsButton(
            label: _index == _pages.length - 1 ? 'Get started' : 'Next',
            onPressed: () {
              if (_index == _pages.length - 1) {
                context.go('/auth/welcome');
              } else {
                _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
              }
            },
          ),
        ],
      ),
    );
  }
}
