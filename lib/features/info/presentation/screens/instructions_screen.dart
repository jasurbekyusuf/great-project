import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/shared/design_system/ds_card.dart';
import 'package:loadme_mobile/shared/widgets/app_scaffold.dart';

// Mirrors `client_frontend_web-master/src/modules/Instructions/index.jsx`.
// TODO: wire to instructions content / video player.
class InstructionsScreen extends ConsumerWidget {
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = context.space;
    final t = context.types;

    final videos = const [
      ('Как разместить груз', '2:14'),
      ('Поиск перевозчиков', '3:08'),
      ('Настройка профиля', '1:42'),
      ('Premium возможности', '4:25'),
    ];

    return AppScaffold(
      title: 'instructions.title'.tr(ref),
      padded: false,
      body: ListView.separated(
        padding: EdgeInsets.fromLTRB(s.lg, s.lg, s.lg, s.xl),
        itemCount: videos.length,
        separatorBuilder: (_, __) => SizedBox(height: s.md),
        itemBuilder: (_, i) {
          final v = videos[i];
          return DsCard(
            onTap: () {},
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                Container(
                  width: 120,
                  height: 80,
                  decoration: BoxDecoration(
                    color: c.surfaceMuted,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(s.radiusLg),
                      bottomLeft: Radius.circular(s.radiusLg),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.play_circle_outline_rounded, color: c.primary, size: 36),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(s.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.$1, style: t.bodyLgMedium),
                        const SizedBox(height: 4),
                        Text(v.$2, style: t.caption),
                      ],
                    ),
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
