import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/shared/widgets/app_scaffold.dart';

// Mirrors `client_frontend_web-master/src/modules/TermsPage/index.jsx`.
// TODO: load actual terms content from backend or assets.
class TermsScreen extends ConsumerWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.types;
    final s = context.space;
    return AppScaffold(
      title: 'profile.terms'.tr(ref),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: s.lg),
        children: [
          Text('1. Общие положения', style: t.h3),
          SizedBox(height: s.sm),
          Text(
            'Используя Loadme.uz, вы принимаете настоящие условия. Если вы не согласны, прекратите использование сервиса.',
            style: t.body,
          ),
          SizedBox(height: s.lg),
          Text('2. Обязанности пользователя', style: t.h3),
          SizedBox(height: s.sm),
          Text(
            'Размещать достоверную информацию о грузах и грузовиках, не нарушать права третьих лиц.',
            style: t.body,
          ),
          SizedBox(height: s.lg),
          Text('3. Ответственность сервиса', style: t.h3),
          SizedBox(height: s.sm),
          Text(
            'Loadme.uz — информационная площадка. Мы не являемся стороной сделок между перевозчиками и заказчиками.',
            style: t.body,
          ),
          SizedBox(height: s.lg),
          Text('4. Изменения условий', style: t.h3),
          SizedBox(height: s.sm),
          Text('Условия могут быть обновлены. Актуальная версия публикуется на этой странице.', style: t.body),
        ],
      ),
    );
  }
}
