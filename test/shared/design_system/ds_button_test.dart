import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadme_mobile/core/theme/app_theme.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
      );

  group('DsButton', () {
    testWidgets('renders label and fires onPressed', (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrap(
        DsButton(
          label: 'Yuborish',
          onPressed: () => taps++,
        ),
      ));

      expect(find.text('Yuborish'), findsOneWidget);
      await tester.tap(find.text('Yuborish'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('does not fire onPressed while loading', (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrap(
        DsButton(
          label: 'Yuborish',
          loading: true,
          onPressed: () => taps++,
        ),
      ));

      await tester.tap(find.byType(InkWell));
      await tester.pump();
      expect(taps, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
