import 'package:flutter/material.dart';

class AppResponsiveContainer extends StatelessWidget {
  const AppResponsiveContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final width = constraints.maxWidth > 720 ? 720.0 : constraints.maxWidth;
        return Center(child: SizedBox(width: width, child: child));
      },
    );
  }
}
