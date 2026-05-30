import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/shared/widgets/app_scaffold.dart';

// Mirrors `client_frontend_web-master/src/modules/FaqPage/index.jsx`.
// TODO: source FAQ items from /faq endpoint or i18n bundle.
class FaqScreen extends ConsumerWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = context.space;
    final t = context.types;

    final items = const [
      ('Как разместить груз?', 'Откройте раздел «Выложить», заполните маршрут, тип груза, вес и цену.'),
      ('Как связаться с заказчиком?', 'Откройте карточку груза и нажмите «Позвонить» или «Telegram».'),
      ('Чем отличается Premium?', 'Premium даёт безлимитный поиск, приоритет в выдаче и расширенную статистику.'),
      ('Как удалить аккаунт?', 'Профиль → Удалить аккаунт. Действие необратимо.'),
    ];

    return AppScaffold(
      title: 'profile.faq'.tr(ref),
      padded: false,
      body: ListView.separated(
        padding: EdgeInsets.fromLTRB(s.lg, s.lg, s.lg, s.xl),
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(height: s.sm),
        itemBuilder: (_, i) {
          final q = items[i];
          return ClipRRect(
            borderRadius: BorderRadius.circular(s.radiusLg),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                backgroundColor: c.surface,
                collapsedBackgroundColor: c.surface,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: c.borderSubtle),
                  borderRadius: BorderRadius.circular(s.radiusLg),
                ),
                collapsedShape: RoundedRectangleBorder(
                  side: BorderSide(color: c.borderSubtle),
                  borderRadius: BorderRadius.circular(s.radiusLg),
                ),
                title: Text(q.$1, style: t.bodyLgMedium),
                children: [Align(alignment: Alignment.centerLeft, child: Text(q.$2, style: t.body))],
              ),
            ),
          );
        },
      ),
    );
  }
}
