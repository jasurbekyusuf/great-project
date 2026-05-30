import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/shared/widgets/app_bottom_nav.dart';
import 'package:loadme_mobile/shared/widgets/mobile_page_head.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.currentNavIndex,
    this.actions,
    this.trailing,
    this.showBack = true,
    this.onBack,
    this.padded = true,
    this.userRole = 'shipper',
  });

  final String title;
  final Widget body;
  final int? currentNavIndex;
  final List<Widget>? actions;
  final Widget? trailing;
  final bool showBack;
  final VoidCallback? onBack;
  final bool padded;
  final String userRole;

  @override
  Widget build(BuildContext context) {
    Widget? trailingWidget = trailing;
    if (trailingWidget == null && actions != null && actions!.isNotEmpty) {
      trailingWidget = Row(mainAxisSize: MainAxisSize.min, children: actions!);
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Column(
        children: [
          MobilePageHead(
            title: title,
            trailing: trailingWidget,
            showBack: showBack,
            onBack: onBack,
          ),
          Expanded(
            child: padded
                ? Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.space.lg),
                    child: body,
                  )
                : body,
          ),
        ],
      ),
      bottomNavigationBar: currentNavIndex == null
          ? null
          : AppBottomNav(currentIndex: currentNavIndex!, userRole: userRole),
    );
  }
}
