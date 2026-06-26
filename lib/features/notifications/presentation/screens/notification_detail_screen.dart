import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key, this.notification});

  final AppNotification? notification;

  static const _sampleTitle = 'Arizalar ochiq — biz siz bilan ishlashga tayyormiz!';
  static const _sampleBody =
      'Loadme jamoasi yangi imkoniyatlarni ishga tushirdi. Endi yuk egalari '
      "va tashuvchilar bir-birini yanada tez topadi: e'lonlar real vaqtda "
      "yangilanadi, tasdiqlangan foydalanuvchilar ustuvor ko'rsatiladi.\n\n"
      "Platformadan to'liq foydalanish uchun profilingizni to'ldiring, "
      "hujjatlaringizni tasdiqlang va kerakli yo'nalishlar bo'yicha "
      "bildirishnomalarni yoqing. Savollaringiz bo'lsa, yordam markaziga "
      'murojaat qiling — biz har doim yordam berishga tayyormiz.';

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final title = (n != null && n.title.isNotEmpty) ? n.title : _sampleTitle;
    final body = (n != null && n.body.isNotEmpty) ? n.body : _sampleBody;
    final hero = n?.imageUrl;

    return AppScaffold(
      title: 'Xabarlar',
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
              _dateLabel(n.createdAt),
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
  static String _dateLabel(DateTime dt) {
    const months = [
      'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
      'Iyul', 'Avgust', 'Sentabr', 'Oktabr', 'Noyabr', 'Dekabr', //
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
