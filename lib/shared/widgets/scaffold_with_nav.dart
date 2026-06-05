import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/auth/presentation/providers/current_user_provider.dart';
import 'package:loadme_mobile/shared/widgets/mobile_auth_required_sheet.dart';

/// Hosts the bottom navigation bar and a [StatefulNavigationShell] body.
///
/// Each branch keeps its own `Navigator` — pushing a detail screen on one tab
/// then switching to another tab and back returns to the same detail, like
/// native iOS apps. Mirrors Material's typical mobile shell pattern.
class ScaffoldWithNav extends ConsumerWidget {
  const ScaffoldWithNav({super.key, required this.shell, this.guest = false});

  final StatefulNavigationShell shell;
  final bool guest;

  void _onItemTap(BuildContext context, int index) {
    // If the user re-taps the active tab, pop to its root.
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = context.space;
    final t = context.types;

    final role = ref.watch(currentUserRoleSyncProvider);
    final isCarrier = role == 'carrier';

    final items = <_NavItem>[
      _NavItem(label: 'nav.search'.tr(ref), icon: Icons.search_rounded),
      _NavItem(label: 'nav.post'.tr(ref), icon: Icons.add_circle_outline_rounded),
      _NavItem(
        label: (isCarrier ? 'nav.myTrucks' : 'nav.myLoads').tr(ref),
        icon: isCarrier ? Icons.local_shipping_outlined : Icons.inventory_2_outlined,
      ),
      _NavItem(label: 'nav.profile'.tr(ref), icon: Icons.person_outline_rounded),
    ];

    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.borderSubtle)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: s.footerBarHeight),
              child: IntrinsicHeight(
                child: Row(
                  children: List.generate(items.length, (i) {
                    final item = items[i];
                    final active = i == shell.currentIndex;
                    final color = active ? c.primary : c.textMuted;
                    return Expanded(
                      child: InkWell(
                        onTap: () {
                          if (guest && i != 0) {
                            showMobileAuthRequiredSheet(context);
                            return;
                          }
                          _onItemTap(context, i);
                        },
                        borderRadius: BorderRadius.circular(s.radiusSm),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(item.icon, size: 22, color: color),
                              const SizedBox(height: 4),
                              Text(
                                item.label,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.overline.copyWith(color: color),
                              ),
                              const SizedBox(height: 4),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: active ? 18 : 0,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: c.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.label, required this.icon});
  final String label;
  final IconData icon;
}
