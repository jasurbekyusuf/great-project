import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/shared/widgets/app_scaffold.dart';

// Mirrors `client_frontend_web-master/src/modules/PrivacyPolicy/index.jsx`.
// TODO: load actual policy markdown / HTML from backend or assets.
class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.types;
    final s = context.space;
    return AppScaffold(
      title: 'profile.privacy'.tr(ref),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: s.lg),
        children: [
          Text('Введение', style: t.h3),
          SizedBox(height: s.sm),
          Text(
            'Loadme.uz уважает вашу конфиденциальность. Этот документ описывает, какие данные мы собираем и как мы их используем.',
            style: t.body,
          ),
          SizedBox(height: s.lg),
          Text('Какие данные мы собираем', style: t.h3),
          SizedBox(height: s.sm),
          Text(
            'ФИО, номер телефона, информация о компании и грузах, технические данные устройства, файлы cookie.',
            style: t.body,
          ),
          SizedBox(height: s.lg),
          Text('Как мы используем данные', style: t.h3),
          SizedBox(height: s.sm),
          Text(
            'Для предоставления услуг, связи между перевозчиками и заказчиками, улучшения сервиса.',
            style: t.body,
          ),
          SizedBox(height: s.lg),
          Text('Контакты', style: t.h3),
          SizedBox(height: s.sm),
          Text('По вопросам конфиденциальности пишите: support@loadme.uz', style: t.body),
        ],
      ),
    );
  }
}
