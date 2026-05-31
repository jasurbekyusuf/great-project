import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadme_mobile/core/theme/app_theme.dart';
import 'package:loadme_mobile/shared/widgets/mobile_segmented_tab.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );

void main() {
  group('MobileSegmentedTab', () {
    testWidgets('renders all labels', (tester) async {
      await tester.pumpWidget(_wrap(
        MobileSegmentedTab(
          items: const ['One', 'Two', 'Three'],
          selectedIndex: 0,
          onChanged: (_) {},
        ),
      ));

      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
      expect(find.text('Three'), findsOneWidget);
    });

    testWidgets('fires onChanged with tapped index', (tester) async {
      var lastIndex = -1;
      await tester.pumpWidget(_wrap(
        MobileSegmentedTab(
          items: const ['A', 'B'],
          selectedIndex: 0,
          onChanged: (i) => lastIndex = i,
        ),
      ));

      await tester.tap(find.text('B'));
      await tester.pump();
      expect(lastIndex, 1);
    });
  });
}
