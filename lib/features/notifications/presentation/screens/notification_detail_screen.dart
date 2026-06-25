import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/shared/widgets/app_scaffold.dart';

/// Figma "Xabarlar" announcement detail (6969:25428 → 6969:42066): a r16 hero
/// image, a date, a heading and a long supporting text, under the shared frosted
/// page head with a bookmark action.
///
/// TODO: drive title/date/body/hero from the /notifications announcement API.
/// For now it renders a representative sample so the layout is visible 1:1.
class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key});

  static const _body =
      'Loadme jamoasi yangi imkoniyatlarni ishga tushirdi. Endi yuk egalari '
      "va tashuvchilar bir-birini yanada tez topadi: e'lonlar real vaqtda "
      "yangilanadi, tasdiqlangan foydalanuvchilar ustuvor ko'rsatiladi.\n\n"
      "Platformadan to'liq foydalanish uchun profilingizni to'ldiring, "
      "hujjatlaringizni tasdiqlang va kerakli yo'nalishlar bo'yicha "
      "bildirishnomalarni yoqing. Savollaringiz bo'lsa, yordam markaziga "
      'murojaat qiling — biz har doim yordam berishga tayyormiz.';

  @override
  Widget build(BuildContext context) {
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
          // Hero image, 343x224 @ r16 (cover).
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 343 / 224,
              child: Image.asset(
                'assets/images/notif_hero_sample.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '20 Yanvar 2024',
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w400,
              color: FigmaPalette.tertiary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Arizalar ochiq — biz siz bilan ishlashga tayyormiz!',
            style: TextStyle(
              fontSize: 16,
              height: 24 / 16,
              fontWeight: FontWeight.w600,
              color: FigmaPalette.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            _body,
            style: TextStyle(
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
}
