import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';
import 'package:loadme_mobile/shared/design_system/ds_card.dart';
import 'package:loadme_mobile/shared/widgets/app_scaffold.dart';

// Mirrors `client_frontend_web-master/src/modules/PremiumPage/index.jsx`.
// TODO: wire to /premium tariff list + checkout flow.
class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  int _selected = 1;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.space;
    final t = context.types;

    final tariffs = [
      ('premium.month1'.tr(ref), '49 000 UZS', null),
      ('premium.month3'.tr(ref), '129 000 UZS', '−12%'),
      ('premium.month12'.tr(ref), '449 000 UZS', '−24%'),
    ];

    final perks = [
      'premium.perk.unlimited'.tr(ref),
      'premium.perk.priority'.tr(ref),
      'premium.perk.stats'.tr(ref),
      'premium.perk.noAds'.tr(ref),
    ];

    return AppScaffold(
      title: 'profile.premium'.tr(ref),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: s.lg),
        children: [
          Container(
            padding: EdgeInsets.all(s.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [c.primary, c.primary500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(s.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 32),
                SizedBox(height: s.sm),
                Text('premium.title'.tr(ref), style: t.h2.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  'premium.subtitle'.tr(ref),
                  style: t.body.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
          SizedBox(height: s.xl),
          Text('premium.chooseTariff'.tr(ref), style: t.h3),
          SizedBox(height: s.md),
          ...List.generate(tariffs.length, (i) {
            final tariff = tariffs[i];
            final active = _selected == i;
            return Padding(
              padding: EdgeInsets.only(bottom: s.sm),
              child: DsCard(
                onTap: () => setState(() => _selected = i),
                borderColor: active ? c.primary : null,
                child: Row(
                  children: [
                    Icon(
                      active ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: active ? c.primary : c.textMuted,
                    ),
                    SizedBox(width: s.md),
                    Expanded(child: Text(tariff.$1, style: t.bodyLgMedium)),
                    if (tariff.$3 != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: c.green600.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(s.radiusXs),
                        ),
                        child: Text(tariff.$3!, style: t.caption.copyWith(color: c.green700)),
                      ),
                      SizedBox(width: s.sm),
                    ],
                    Text(tariff.$2, style: t.bodyLgMedium),
                  ],
                ),
              ),
            );
          }),
          SizedBox(height: s.xl),
          Text('premium.includes'.tr(ref), style: t.h3),
          SizedBox(height: s.md),
          DsCard(
            child: Column(
              children: perks
                  .map((p) => Padding(
                        padding: EdgeInsets.symmetric(vertical: s.xs),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: c.primary, size: 20),
                            SizedBox(width: s.sm),
                            Expanded(child: Text(p, style: t.body)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          SizedBox(height: s.xl),
          DsButton(label: 'premium.subscribe'.tr(ref), onPressed: () {}),
        ],
      ),
    );
  }
}
