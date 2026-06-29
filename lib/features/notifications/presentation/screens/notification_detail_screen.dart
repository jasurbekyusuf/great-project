import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:loadme_mobile/shared/widgets/app_scaffold.dart';

/// Figma "Xabarlar" announcement detail (6969:25428 → 6969:42066): a r16 hero
/// image (when the notification carries one), a date, a heading and the body,
/// under the shared frosted page head with a bookmark action.
///
/// Driven by the [AppNotification] passed via `GoRoute.extra` from the list. A
/// direct deep-link (no extra) falls back to a generic sample so the layout is
/// never blank.
class NotificationDetailScreen extends ConsumerWidget {
  const NotificationDetailScreen({super.key, this.notification});

  final AppNotification? notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = notification;
    final title = (n != null && n.title.isNotEmpty)
        ? n.title
        : 'notifications.sample.title'.tr(ref);
    final body = (n != null && n.body.isNotEmpty)
        ? n.body
        : 'notifications.sample.body'.tr(ref);
    final hero = n?.imageUrl;

    return AppScaffold(
      title: 'notifications.title'.tr(ref),
      backgroundColor: FigmaPalette.sheetBg,
      padded: false,
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 4),
          child: Icon(LucideIcons.bookmark, size: 22, color: FigmaPalette.ink),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (hero != null && hero.isNotEmpty) ...[
            // Hero image, 343x224 @ r16 (cover).
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 343 / 224,
                child: Image.network(
                  hero,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (n != null) ...[
            Text(
              _dateLabel(n.createdAt, ref),
              style: const TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w400,
                color: FigmaPalette.tertiary,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              height: 24 / 16,
              fontWeight: FontWeight.w600,
              color: FigmaPalette.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 16,
              height: 23 / 16,
              fontWeight: FontWeight.w400,
              color: FigmaPalette.inkBody,
            ),
          ),
        ],
      ),
    );
  }

  /// ISO datetime → Uzbek "26 Iyun 2026" (month capitalised, as in Figma).
  static String _dateLabel(DateTime dt, WidgetRef ref) {
    final months = 'common.months'.tr(ref).split(',');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
