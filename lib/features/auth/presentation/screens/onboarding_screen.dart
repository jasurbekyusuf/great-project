import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/auth/presentation/widgets/auth_step_dots.dart';
import 'package:loadme_mobile/features/auth/presentation/widgets/auth_shell.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // Localized titles/bodies for the three onboarding cards (cannot be a
    // `const` field because each value comes from `.tr(ref)`).
    final pages = [
      ('onboarding.page1Title'.tr(ref), 'onboarding.page1Body'.tr(ref)),
      ('onboarding.page2Title'.tr(ref), 'onboarding.page2Body'.tr(ref)),
      ('onboarding.page3Title'.tr(ref), 'onboarding.page3Body'.tr(ref)),
    ];
    return AuthShell(
      title: 'onboarding.shellTitle'.tr(ref),
      subtitle: 'onboarding.shellSubtitle'.tr(ref),
      child: Column(
        children: [
          SizedBox(
            height: 280,
            child: PageView.builder(
              controller: _pageController,
              itemCount: pages.length,
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
                    Text(pages[i].$1, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                    SizedBox(height: context.space.sm),
                    Text(pages[i].$2, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: context.space.lg),
          AuthStepDots(current: _index, total: pages.length),
          SizedBox(height: context.space.xl),
          DsButton(
            label: _index == pages.length - 1
                ? 'onboarding.getStarted'.tr(ref)
                : 'common.next'.tr(ref),
            onPressed: () {
              if (_index == pages.length - 1) {
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
