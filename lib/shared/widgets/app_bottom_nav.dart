import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/auth/presentation/providers/current_user_provider.dart';
import 'package:loadme_mobile/shared/widgets/mobile_auth_required_sheet.dart';

enum AppNavTab { search, post, my, profile }

// Context-aware bottom navigation. The 3rd tab adapts to the current area:
//   - On any /loads or /my-loads route → "Mening yuklarim" + box icon
//   - On any /trucks or /my-trucks route → "Ulovlarim" + truck icon
// Also honours an explicit `userRole` override (legacy carrier hint).
class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    this.userRole,
    this.guest = false,
  });

  final int currentIndex;
  final String? userRole;
  final bool guest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = context.space;
    final t = context.types;

    final role = userRole ?? ref.watch(currentUserRoleSyncProvider);
    final currentPath = GoRouterState.of(context).matchedLocation;
    final isTrucksArea = role == 'carrier' ||
        currentPath.contains('truck') ||
        currentPath == '/guest-trucks';

    final items = <_NavItem>[
      _NavItem(
        label: 'nav.search'.tr(ref),
        icon: Icons.search_rounded,
        path: guest ? '/guest' : (isTrucksArea ? '/trucks' : '/loads'),
      ),
      _NavItem(
        label: 'nav.post'.tr(ref),
        icon: Icons.add_circle_outline_rounded,
        path: isTrucksArea ? '/add-post-truck' : '/add-load',
      ),
      _NavItem(
        label: (isTrucksArea ? 'nav.myTrucks' : 'nav.myLoads').tr(ref),
        icon: isTrucksArea ? Icons.local_shipping_outlined : Icons.inventory_2_outlined,
        path: isTrucksArea ? '/my-trucks' : '/my-loads',
      ),
      _NavItem(
        label: 'nav.profile'.tr(ref),
        icon: Icons.person_outline_rounded,
        path: '/profile',
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.borderSubtle, width: 1)),
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
                  final active = i == currentIndex;
                  final color = active ? c.primary : c.textMuted;
                  return Expanded(
                    child: InkWell(
                      onTap: () {
                        if (guest && item.path != '/guest') {
                          showMobileAuthRequiredSheet(context);
                          return;
                        }
                        context.go(item.path);
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
    );
  }
}

class _NavItem {
  const _NavItem({required this.label, required this.icon, required this.path});
  final String label;
  final IconData icon;
  final String path;
}
