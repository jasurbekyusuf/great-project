import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/shared/design_system/ds_illustration_empty.dart';
import 'package:loadme_mobile/shared/widgets/app_scaffold.dart';

// Figma "Xabarlar" (6969:25034): a frosted page head, then notifications
// grouped by "Bugun" / "Bu hafta". Each card is a 40x40 icon tile plus a
// title (with a red unread dot), a body and, for actionable items, a blue
// "Ko'rish ↗" button. Read cards use the muted #FCFCFD surface.
//
// TODO: wire to /notifications endpoint, mark-as-read mutation, push
// integration. The grouped data below is a representative placeholder so the
// redesigned cards are visible until the backend is connected.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  List<_NotifGroup> _demoGroups() => const [
        _NotifGroup('Bugun', [
          _NotificationItem(
            kind: _NotifKind.load,
            title: 'Yangi yuk topildi!',
            body: "Samarqand-Toshkent yo'nalishi bo'yicha yangi yuk qo'yildi",
            unread: true,
            actionable: true,
          ),
          _NotificationItem(
            kind: _NotifKind.system,
            title: 'Loadme ga xush kelibsiz!',
            body: "Loadme tizimini o'rganishni boshlang va barcha "
                'imkoniyatlardan foydalaning.',
          ),
        ]),
        _NotifGroup('Bu hafta', [
          _NotificationItem(
            kind: _NotifKind.system,
            title: 'Loadme ga xush kelibsiz!',
            body: "Loadme tizimini o'rganishni boshlang va barcha "
                'imkoniyatlardan foydalaning.',
          ),
          _NotificationItem(
            kind: _NotifKind.system,
            title: 'Profilingiz tasdiqlandi',
            body: "Hujjatlaringiz tekshirildi. Endi e'lon joylashingiz mumkin.",
            unread: true,
          ),
          _NotificationItem(
            kind: _NotifKind.load,
            title: 'Yangi yuk topildi!',
            body: "Toshkent-Buxoro yo'nalishi bo'yicha yangi yuk qo'yildi",
            unread: true,
            actionable: true,
          ),
          _NotificationItem(
            kind: _NotifKind.system,
            title: 'Loadme ga xush kelibsiz!',
            body: "Loadme tizimini o'rganishni boshlang va barcha "
                'imkoniyatlardan foydalaning.',
          ),
        ]),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = _demoGroups();
    final isEmpty = groups.every((g) => g.items.isEmpty);

    return AppScaffold(
      title: 'notifications.title'.tr(ref),
      // Figma Xabarlar frame fill (6804:11447) is #F3F4F7 (sheetBg).
      backgroundColor: FigmaPalette.sheetBg,
      padded: false,
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 4),
          child: Icon(LucideIcons.bookmark, size: 22, color: FigmaPalette.ink),
        ),
      ],
      body: isEmpty
          ? DsIllustrationEmpty(
              // Figma Xabarlar empty (6804:11447): box+magnet art with a
              // taller shadow halo (231×208) and no action button.
              asset: 'assets/images/empty_notifications.png',
              message: 'notifications.empty'.tr(ref),
              gap: 8,
              haloSize: const Size(231, 208),
              haloOffset: const Offset(-16, -16),
            )
          : ListView(
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
                      onTap: () => context.push('/notifications/announcement'),
                    ),
                  ],
                ],
              ],
            ),
    );
  }
}

enum _NotifKind { load, system }

class _NotifGroup {
  const _NotifGroup(this.label, this.items);
  final String label;
  final List<_NotificationItem> items;
}

class _NotificationItem {
  const _NotificationItem({
    required this.kind,
    required this.title,
    required this.body,
    this.unread = false,
    this.actionable = false,
  });

  final _NotifKind kind;
  final String title;
  final String body;

  /// Unread → white surface, dark title, red dot. Read → #FCFCFD, all muted.
  final bool unread;

  /// Shows the blue "Ko'rish ↗" button (new-load notifications).
  final bool actionable;
}

/// One Figma notification card (343 wide, pad12, r16, gap8).
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, this.onTap});

  final _NotificationItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final unread = item.unread;
    final bg = unread ? Colors.white : FigmaPalette.notifCardRead;
    final titleColor = unread ? FigmaPalette.notifTitle : FigmaPalette.inkMuted;
    final bodyColor = unread ? FigmaPalette.inkBody : FigmaPalette.inkMuted;
    final icon =
        item.kind == _NotifKind.load ? LucideIcons.package : LucideIcons.bell;

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
                            item.title,
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
                    if (item.actionable) ...[
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

/// Blue "Ko'rish ↗" pill (#004EEB, r8) shown on new-load notifications.
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
