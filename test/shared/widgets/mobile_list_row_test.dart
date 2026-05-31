import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadme_mobile/core/theme/app_theme.dart';
import 'package:loadme_mobile/shared/widgets/mobile_list_row.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );

void main() {
  group('MobileListRow', () {
    testWidgets('renders title + subtitle and fires onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        MobileListRow(
          title: 'Settings',
          subtitle: 'App preferences',
          leadingIcon: Icons.settings,
          onTap: () => tapped = true,
        ),
      ));

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('App preferences'), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('shows chevron by default, hides when showChevron=false',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const MobileListRow(title: 'A'),
      ));
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      await tester.pumpWidget(_wrap(
        const MobileListRow(title: 'B', showChevron: false),
      ));
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    });
  });

  group('MobileListGroup', () {
    testWidgets('grouped variant inserts dividers between children',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const MobileListGroup(
          children: [
            MobileListRow(title: 'A'),
            MobileListRow(title: 'B'),
            MobileListRow(title: 'C'),
          ],
        ),
      ));
      // 3 items → 2 dividers
      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('separated variant has no dividers', (tester) async {
      await tester.pumpWidget(_wrap(
        const MobileListGroup(
          variant: MobileListGroupVariant.separated,
          children: [
            MobileListRow(title: 'A'),
            MobileListRow(title: 'B'),
          ],
        ),
      ));
      expect(find.byType(Divider), findsNothing);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });
  });
}
