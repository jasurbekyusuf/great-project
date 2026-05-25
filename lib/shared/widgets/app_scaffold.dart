import 'package:flutter/material.dart';
import 'package:loadme_mobile/shared/widgets/app_bottom_nav.dart';
import 'package:loadme_mobile/shared/widgets/app_responsive_container.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.currentNavIndex,
    this.actions,
  });

  final String title;
  final Widget body;
  final int? currentNavIndex;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: AppResponsiveContainer(child: body),
      bottomNavigationBar: currentNavIndex == null ? null : AppBottomNav(currentIndex: currentNavIndex!),
    );
  }
}
