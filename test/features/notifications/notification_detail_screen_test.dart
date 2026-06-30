import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/app_theme.dart';
import 'package:loadme_mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:loadme_mobile/features/notifications/presentation/screens/notification_detail_screen.dart';

Widget _app(AppNotification n) => ProviderScope(
      overrides: [
        // `.tr(ref)` reads appL10nProvider -> localeProvider -> SharedPreferences
        // (which is "Override in main"); pin a locale so the chain never runs.
        appL10nProvider.overrideWithValue(AppL10n(const Locale('uz'))),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: NotificationDetailScreen(notification: n),
      ),
    );

void main() {
  testWidgets('announcement detail renders the content but has no saved/bookmark action',
      (tester) async {
    // No imageUrl, so the screen never reaches out for a hero image (network is
    // blocked in the sandbox).
    await tester.pumpWidget(
      _app(
        AppNotification(
          id: '1',
          title: 'Yangi e’lon',
          body: 'E’lon matni',
          type: 'announcement',
          isRead: true,
          createdAt: DateTime(2026, 6, 26),
          kind: NotificationKind.system,
        ),
      ),
    );
    await tester.pump();

    // Body content is present…
    expect(find.text('Yangi e’lon'), findsOneWidget);
    expect(find.text('E’lon matni'), findsOneWidget);

    // …but the page-head bookmark icon the tester flagged ("buyerda saved icon
    // kerak emas") must be gone.
    expect(find.byIcon(LucideIcons.bookmark), findsNothing);
  });
}
