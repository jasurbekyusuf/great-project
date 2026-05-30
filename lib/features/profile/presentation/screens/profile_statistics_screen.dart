import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/shared/design_system/ds_card.dart';
import 'package:loadme_mobile/shared/widgets/app_scaffold.dart';

// Mirrors `client_frontend_web-master/src/modules/ProfileStatistics/index.jsx`.
// TODO: wire to /statistics API.
class ProfileStatisticsScreen extends ConsumerWidget {
  const ProfileStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = context.space;
    final t = context.types;

    final tiles = [
      _StatTile(label: 'stats.activeLoads'.tr(ref), value: '12', icon: Icons.inventory_2_outlined),
      _StatTile(label: 'stats.completed'.tr(ref), value: '84', icon: Icons.task_alt_rounded),
      _StatTile(label: 'stats.activeTrucks'.tr(ref), value: '4', icon: Icons.local_shipping_outlined),
      _StatTile(label: 'stats.profileViews'.tr(ref), value: '1 245', icon: Icons.remove_red_eye_outlined),
    ];

    return AppScaffold(
      title: 'profile.statistics'.tr(ref),
      body: ListView(
        padding: EdgeInsets.only(top: s.lg, bottom: s.xxl),
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: s.md,
            mainAxisSpacing: s.md,
            childAspectRatio: 1.3,
            children: tiles
                .map((tile) => DsCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(tile.icon, color: c.primary, size: 22),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tile.value, style: t.h1),
                              const SizedBox(height: 2),
                              Text(tile.label, style: t.caption),
                            ],
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
          SizedBox(height: s.xl),
          DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('stats.monthlyActivity'.tr(ref), style: t.h3),
                SizedBox(height: s.md),
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: c.surfaceMuted,
                    borderRadius: BorderRadius.circular(s.radiusSm),
                  ),
                  alignment: Alignment.center,
                  child: Text('stats.chart'.tr(ref), style: t.caption),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile {
  const _StatTile({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
}
