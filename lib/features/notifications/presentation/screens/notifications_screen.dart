import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:loadme_mobile/shared/design_system/ds_illustration_empty.dart';
import 'package:loadme_mobile/shared/widgets/app_scaffold.dart';

// Figma "Xabarlar" (6969:25034): a frosted page head, then notifications
// grouped by "Bugun" / "Bu hafta". Each card is a 40x40 icon tile plus a title
// (with a red unread dot), a body and, for actionable items, a blue
// "Ko'rish ↗" button. Read cards use the muted #FCFCFD surface.
//
// Driven by the real `/notifications/` endpoint via [notificationsControllerProvider]:
// tapping a card marks it read; the bookmark action marks all read.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsControllerProvider);
    final controller = ref.read(notificationsControllerProvider.notifier);

    return AppScaffold(
      title: 'notifications.title'.tr(ref),
      // Figma Xabarlar frame fill (6804:11447) is #F3F4F7 (sheetBg).
      backgroundColor: FigmaPalette.sheetBg,
      padded: false,
      actions: [
        Tooltip(
          message: "Hammasini o'qilgan deb belgilash",
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => unawaited(controller.markAllRead()),
            child: const Padding(
              padding: EdgeInsets.only(left: 8, right: 4),
              child:
                  Icon(LucideIcons.bookmark, size: 22, color: FigmaPalette.ink),
            ),
          ),
        ),
      ],
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: FigmaPalette.primary),
        ),
        error: (e, _) => _ErrorView(onRetry: controller.refresh),
        data: (items) => items.isEmpty
            ? DsIllustrationEmpty(
                // Figma Xabarlar empty (6804:11447): box+magnet art with a
                // taller shadow halo (231×208) and no action button.
                asset: 'assets/images/empty_notifications.png',
                message: 'notifications.empty'.tr(ref),
                gap: 8,
                haloSize: const Size(231, 208),
                haloOffset: const Offset(-16, -16),
              )
            : RefreshIndicator(
                color: FigmaPalette.primary,
                onRefresh: controller.refresh,
                child: _list(context, ref, _group(items)),
              ),
      ),
    );
  }

  Widget _list(BuildContext context, WidgetRef ref, List<_Section> groups) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        for (var gi = 0; gi < groups.length; gi++) ...[
          if (gi > 0) const SizedBox(height: 16),
          Text(
            groups[gi].label,
            style: const TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w500,
              color: FigmaPalette.inkMuted,
            ),
          ),
          const SizedBox(height: 8),
          for (var ci = 0; ci < groups[gi].items.length; ci++) ...[
            if (ci > 0) const SizedBox(height: 8),
            _NotificationCard(
              item: groups[gi].items[ci],
              onTap: () => _open(context, ref, groups[gi].items[ci]),
            ),
          ],
        ],
      ],
    );
  }

  void _open(BuildContext context, WidgetRef ref, AppNotification item) {
    unawaited(
      ref.read(notificationsControllerProvider.notifier).markRead(item.id),
    );
    unawaited(context.push('/notifications/announcement', extra: item));
  }

  /// Buckets newest-first notifications into "Bugun", "Bu hafta" (last 7 days)
  /// and "Avvalroq" (older). Empty buckets are dropped.
  List<_Section> _group(List<AppNotification> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 6));
    final bugun = <AppNotification>[];
    final hafta = <AppNotification>[];
    final avval = <AppNotification>[];
    for (final n in items) {
      final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      if (d == today) {
        bugun.add(n);
      } else if (!d.isBefore(weekStart)) {
        hafta.add(n);
      } else {
        avval.add(n);
      }
    }
    return [
      if (bugun.isNotEmpty) _Section('Bugun', bugun),
      if (hafta.isNotEmpty) _Section('Bu hafta', hafta),
      if (avval.isNotEmpty) _Section('Avvalroq', avval),
    ];
  }
}

class _Section {
  const _Section(this.label, this.items);
  final String label;
  final List<AppNotification> items;
}

/// One Figma notification card (343 wide, pad12, r16, gap8).
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, this.onTap});

  final AppNotification item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !item.isRead;
    final bg = unread ? Colors.white : FigmaPalette.notifCardRead;
    final titleColor = unread ? FigmaPalette.notifTitle : FigmaPalette.inkMuted;
    final bodyColor = unread ? FigmaPalette.inkBody : FigmaPalette.inkMuted;
    final icon = item.kind == NotificationKind.load
        ? LucideIcons.package
        : LucideIcons.bell;
    final title = item.title.isNotEmpty ? item.title : 'Bildirishnoma';

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 40x40 icon tile, r10, #EAEFF5.
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: FigmaPalette.notifIconTile,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: titleColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + (optional) 7px red unread dot.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.w500,
                              color: titleColor,
                            ),
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 8),
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: FigmaPalette.unreadDot,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (item.body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.body,
                        style: TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w400,
                          color: bodyColor,
                        ),
                      ),
                    ],
                    if (item.kind == NotificationKind.load) ...[
                      const SizedBox(height: 8),
                      _SeeButton(onTap: onTap),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Blue "Ko'rish ↗" pill (#004EEB, r8) shown on load notifications.
class _SeeButton extends StatelessWidget {
  const _SeeButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: FigmaPalette.primary,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 12, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Ko'rish",
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 4),
                Icon(LucideIcons.arrowUpRight, size: 18, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline error + retry for a failed initial load.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.triangleAlert,
                size: 40, color: FigmaPalette.inkMuted),
            const SizedBox(height: 12),
            const Text(
              "Xabarlarni yuklab bo'lmadi",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: FigmaPalette.notifTitle,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => unawaited(onRetry()),
              child: const Text(
                'Qayta urinish',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: FigmaPalette.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
