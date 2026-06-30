import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/features/auth/presentation/providers/current_user_provider.dart';
import 'package:loadme_mobile/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:loadme_mobile/shared/design_system/ds_illustration_empty.dart';
import 'package:loadme_mobile/shared/widgets/frosted_header.dart';
import 'package:loadme_mobile/shared/widgets/mobile_segmented_tab.dart';

// Figma "Xabarlar" (6969:25034): a frosted page head, then notifications
// grouped by "Bugun" / "Bu hafta". Each card is a 40x40 icon tile plus a title
// (with a red unread dot), a body and, for actionable items, a blue
// "Ko'rish ↗" button. Read cards use the muted #FCFCFD surface.
//
// Driven by the real `/notifications/` endpoint via [notificationsControllerProvider]:
// tapping a card marks it read. The Figma header (6804:11446) is just a back
// chevron + centered "Xabarlar" with NO right-side action, so there is no
// mark-all-read control in the bar.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  // The redesign (Figma 6804:11446) splits the single `/notifications/` feed
  // into two tabs by kind: "Magnit" = load-match alerts (NotificationKind.load
  // — the "Sizga mos yuklar" cards), "Tizim xabarlari" = everything else. Both
  // tabs render off the one fetch, so switching is instant and never re-hits
  // the network.
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificationsControllerProvider);
    final controller = ref.read(notificationsControllerProvider.notifier);

    // Magnit (load-match alerts) is a driver-only feature, so the "Magnit"
    // tab only makes sense for carriers. Shipper/broker get a single,
    // untabbed feed — no Magnit surface for them.
    final isCarrier = ref.watch(currentUserRoleSyncProvider) == 'carrier';

    // Figma "Xabarlar" (6969:25034) puts the title row AND the segmented tabs
    // inside one frosted, rounded-bottom header (same as the Garaj page),
    // floating over the #F3F4F7 (sheetBg) frame.
    return Scaffold(
      backgroundColor: FigmaPalette.sheetBg,
      body: Column(
        children: [
          FrostedHeader(
            title: 'notifications.title'.tr(ref),
            bottom: isCarrier
                ? MobileSegmentedTab(
                    // Figma segmented control is 36 tall (thumb 32), not the
                    // app-default 40.
                    height: 36,
                    items: [
                      'notifications.tab.magnit'.tr(ref),
                      'notifications.tab.system'.tr(ref),
                    ],
                    selectedIndex: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  )
                : null,
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: FigmaPalette.primary),
              ),
              error: (e, _) => _ErrorView(onRetry: controller.refresh),
              data: (items) =>
                  _tabBody(context, items, controller.refresh, isCarrier),
            ),
          ),
        ],
      ),
    );
  }

  /// The active tab's content: the feed filtered to the tab's
  /// [NotificationKind], then date-grouped — or the shared empty state when
  /// that kind is absent from the feed.
  Widget _tabBody(
    BuildContext context,
    List<AppNotification> items,
    Future<void> Function() onRefresh,
    bool isCarrier,
  ) {
    // Carriers split the feed by tab (Magnit vs system); everyone else sees
    // the whole feed in one list since Magnit doesn't apply to them.
    final filtered = isCarrier
        ? items
            .where((n) =>
                n.kind ==
                (_tab == 0 ? NotificationKind.load : NotificationKind.system))
            .toList()
        : items;
    if (filtered.isEmpty) {
      return DsIllustrationEmpty(
        // Figma Xabarlar empty (6804:11447): box+magnet art with a
        // taller shadow halo (231×208) and no action button.
        asset: 'assets/images/empty_notifications.png',
        message: 'notifications.empty'.tr(ref),
        gap: 8,
        haloSize: const Size(231, 208),
        haloOffset: const Offset(-16, -16),
      );
    }
    return RefreshIndicator(
      color: FigmaPalette.primary,
      onRefresh: onRefresh,
      child: _list(context, _group(filtered)),
    );
  }

  Widget _list(BuildContext context, List<_Section> groups) {
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
              onTap: () => _open(context, groups[gi].items[ci]),
            ),
          ],
        ],
      ],
    );
  }

  void _open(BuildContext context, AppNotification item) {
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
      if (bugun.isNotEmpty)
        _Section('notifications.group.today'.tr(ref), bugun),
      if (hafta.isNotEmpty)
        _Section('notifications.group.week'.tr(ref), hafta),
      if (avval.isNotEmpty)
        _Section('notifications.group.earlier'.tr(ref), avval),
    ];
  }
}

class _Section {
  const _Section(this.label, this.items);
  final String label;
  final List<AppNotification> items;
}

/// One Figma notification card (343 wide, pad12, r16, gap8).
class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.item, this.onTap});

  final AppNotification item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = !item.isRead;
    final bg = unread ? Colors.white : FigmaPalette.notifCardRead;
    final titleColor = unread ? FigmaPalette.notifTitle : FigmaPalette.inkMuted;
    final bodyColor = unread ? FigmaPalette.inkBody : FigmaPalette.inkMuted;
    final icon = item.kind == NotificationKind.load
        ? LucideIcons.package
        : LucideIcons.bell;
    final title = item.title.isNotEmpty
        ? item.title
        : 'notifications.cardFallback'.tr(ref);

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
class _SeeButton extends ConsumerWidget {
  const _SeeButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: FigmaPalette.primary,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'notifications.see'.tr(ref),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(LucideIcons.arrowUpRight,
                    size: 18, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline error + retry for a failed initial load.
class _ErrorView extends ConsumerWidget {
  const _ErrorView({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.triangleAlert,
                size: 40, color: FigmaPalette.inkMuted),
            const SizedBox(height: 12),
            Text(
              'notifications.error.title'.tr(ref),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: FigmaPalette.notifTitle,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => unawaited(onRetry()),
              child: Text(
                'notifications.error.retry'.tr(ref),
                style: const TextStyle(
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
