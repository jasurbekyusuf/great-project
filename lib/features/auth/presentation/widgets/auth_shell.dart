import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/shared/widgets/app_responsive_container.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.bottom,
    this.showBack = false,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? bottom;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AppResponsiveContainer(
          child: Padding(
            padding: EdgeInsets.all(context.space.lg),
            child: Column(
              children: [
                if (showBack) Align(alignment: Alignment.centerLeft, child: IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back))),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: context.space.lg),
                        Text(title, style: Theme.of(context).textTheme.headlineMedium),
                        SizedBox(height: context.space.sm),
                        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                        SizedBox(height: context.space.xl),
                        child,
                      ],
                    ),
                  ),
                ),
                if (bottom != null) bottom!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
