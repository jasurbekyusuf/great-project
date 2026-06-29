import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/app_theme.dart';
import 'package:loadme_mobile/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:loadme_mobile/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:loadme_mobile/shared/design_system/ds_illustration_empty.dart';

/// Serves a fixed feed so the screen never touches Dio: `build` is overridden,
/// so the repository getter (and the network) is never reached.
class _FakeNotifications extends NotificationsController {
  _FakeNotifications(this._items);

  final List<AppNotification> _items;

  @override
  Future<List<AppNotification>> build() async => _items;
}

AppNotification _n(String id, String title, NotificationKind kind) =>
    AppNotification(
      id: id,
      title: title,
      body: 'body $id',
      type: kind == NotificationKind.load ? 'load' : 'announcement',
      isRead: false,
      createdAt: DateTime.now(),
      kind: kind,
    );

Widget _app(List<AppNotification> items) => ProviderScope(
      overrides: [
        // `.tr(ref)` reads appL10nProvider -> localeProvider -> SharedPreferences
        // (which is "Override in main"); pin a locale so the chain never runs.
        appL10nProvider.overrideWithValue(AppL10n(const Locale('uz'))),
        notificationsControllerProvider
            .overrideWith(() => _FakeNotifications(items)),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const NotificationsScreen(),
      ),
    );

void main() {
  group('NotificationsScreen — Magnit / Tizim xabarlari split', () {
    testWidgets('each tab shows only its NotificationKind', (tester) async {
      await tester.pumpWidget(_app([
        _n('1', 'Yuk topildi', NotificationKind.load),
        _n('2', 'Tizim yangilandi', NotificationKind.system),
      ]));
      await tester.pump(); // resolve the async build

      // Default tab is "Magnit": load-kind visible, system hidden (the other
      // tab's body isn't built at all).
      expect(find.text('Yuk topildi'), findsOneWidget);
      expect(find.text('Tizim yangilandi'), findsNothing);

      // Switch to "Tizim xabarlari" (the tab label, not a card title).
      await tester.tap(find.text('Tizim xabarlari'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Tizim yangilandi'), findsOneWidget);
      expect(find.text('Yuk topildi'), findsNothing);
    });

    testWidgets('a tab with no matching kind shows the empty state',
        (tester) async {
      // Only a system notification exists, so the "Magnit" tab (load-kind) is
      // empty and must fall back to the illustration rather than blank.
      await tester.pumpWidget(_app([
        _n('2', 'Tizim yangilandi', NotificationKind.system),
      ]));
      await tester.pump();

      expect(find.byType(DsIllustrationEmpty), findsOneWidget);
      expect(find.text('Tizim yangilandi'), findsNothing);
    });
  });

  group('NotificationsScreen — header is 1:1 with Figma (6804:11446)', () {
    testWidgets('shows the centered "Xabarlar" title and no mark-all-read icon',
        (tester) async {
      await tester.pumpWidget(_app([
        _n('1', 'Yuk topildi', NotificationKind.load),
      ]));
      await tester.pump();

      // Header title (uz locale). 'Tizim xabarlari' is a tab label, so an exact
      // match isolates the page-head title.
      expect(find.text('Xabarlar'), findsOneWidget);

      // Figma's header has only a back chevron + centered title — the old ✓✓
      // (checkCheck) "mark all read" action must be gone.
      expect(find.byIcon(LucideIcons.checkCheck), findsNothing);
    });
  });
}
