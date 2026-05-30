import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/shared/design_system/ds_card.dart';
import 'package:loadme_mobile/shared/widgets/app_scaffold.dart';

// Mirrors `client_frontend_web-master/src/modules/Notifications/index.jsx`.
// TODO: wire to /notifications endpoint, mark-as-read mutation, push integration.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = context.space;
    final t = context.types;

    final items = List.generate(
      8,
      (i) => _Notification(
        title: (i.isEven ? 'notifications.new' : 'notifications.loadUpdated').tr(ref),
        body: 'Ташкент → Самарканд · 14:25',
        unread: i < 3,
      ),
    );

    return AppScaffold(
      title: 'notifications.title'.tr(ref),
      padded: false,
      body: ListView.separated(
        padding: EdgeInsets.fromLTRB(s.lg, s.lg, s.lg, s.xl),
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(height: s.sm),
        itemBuilder: (_, i) {
          final n = items[i];
          return DsCard(
            background: n.unread ? c.primary50 : null,
            borderColor: n.unread ? c.primary50 : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, right: 10),
                  decoration: BoxDecoration(
                    color: n.unread ? c.primary : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.title, style: t.bodyLgMedium),
                      const SizedBox(height: 2),
                      Text(n.body, style: t.caption),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Notification {
  _Notification({required this.title, required this.body, required this.unread});
  final String title;
  final String body;
  final bool unread;
}
