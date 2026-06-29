import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Floating pill bottom navigation — pixel-faithful port of the Figma
/// `Nav_bar` (frame 6435:34667).
///
/// Visual layout:
///   ┌──────────────────────────────────────────────┐
///   │ 🔍 Asosiy  🏬 Garaj  [🧲 FAB]  🔔 Xabarlar  👤 Profil │
///   └──────────────────────────────────────────────┘
///
/// The center "FAB" slot renders a raised blue circle that overshoots the
/// pill by half its height. Use the same widget in both the authed shell
/// and guest mode so the chrome stays identical.
class FloatingMarketNav extends ConsumerWidget {
  const FloatingMarketNav({
    super.key,
    required this.activeIndex,
    required this.onTap,
    this.secondLabel = 'Garaj',
    this.secondIcon = LucideIcons.warehouse,
    this.fabIcon = LucideIcons.magnet,
  });

  /// 0..4 (Asosiy, Garaj/Yuklarim, FAB, Xabarlar, Profil) or null.
  final int? activeIndex;

  /// Called with the tapped nav index (0..4).
  final ValueChanged<int> onTap;

  // Slot 1 + the centre FAB vary by role — carrier: "Garaj" + magnet (Magnit);
  // shipper / broker: "Yuklarim" + plus (post a load).
  final String secondLabel;
  final IconData secondIcon;
  final IconData fabIcon;

  // Figma `Nav_bar` (frame 6435:34667 → Frame 2087329689):
  //   pill 356×60, radius 32, shadow 0 1 6 rgba(0,0,0,0.16)
  //   centre FAB 64×64, #004EEB, shadow 0 6 10 rgba(0,41,122,0.2)
  static const _fabSize = 64.0;
  static const _pillHeight = 60.0;
  static const _pillRadius = 32.0;
  static const _fabOvershoot = 34.0;

  /// Height the bar reserves above the bottom safe-area inset (pill + raised
  /// FAB + outer margin). Add it to sticky content so it clears the floating
  /// nav instead of hard-coding a guess.
  static const double reservedHeight = _pillHeight + _fabOvershoot + 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsCountProvider);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: SizedBox(
          height: _pillHeight + _fabOvershoot,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // ── Floating frosted-glass pill ────────────────────────
              // Figma `Frame 2087329689`: background rgba(255,255,255,0.2)
              // with a backdrop blur — the list scrolls behind it (the host
              // Scaffold sets extendBody: true).
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _pillHeight,
                child: DecoratedBox(
                  // Shadow lives outside the clip so it isn't blurred away.
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_pillRadius),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x29000000), // rgba(0,0,0,0.16)
                        offset: Offset(0, 1),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_pillRadius),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(_pillRadius),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _NavSlot(
                                label: 'nav.home'.tr(ref),
                                icon: LucideIcons.search,
                                active: activeIndex == 0,
                                onTap: () => onTap(0),
                              ),
                            ),
                            Expanded(
                              child: _NavSlot(
                                label: secondLabel,
                                icon: secondIcon,
                                active: activeIndex == 1,
                                onTap: () => onTap(1),
                              ),
                            ),
                            // Reserve the centre slot for the raised FAB.
                            const SizedBox(width: _fabSize),
                            Expanded(
                              child: _NavSlot(
                                label: 'nav.messages'.tr(ref),
                                icon: LucideIcons.bell,
                                active: activeIndex == 3,
                                onTap: () => onTap(3),
                                badgeCount: unread,
                              ),
                            ),
                            Expanded(
                              child: _NavSlot(
                                label: 'nav.profile'.tr(ref),
                                icon: LucideIcons.user,
                                active: activeIndex == 4,
                                onTap: () => onTap(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // ── Raised centre FAB ───────────────────────────────────
              Positioned(
                bottom: _pillHeight - _fabSize / 2,
                child: _CenterFab(
                  active: activeIndex == 2,
                  icon: fabIcon,
                  onTap: () => onTap(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.badgeCount = 0,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  /// Unread count drawn as a red badge over the icon's top-right. 0 hides it;
  /// anything over 99 shows "99+".
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    // Figma: active #004EEB, inactive #6C7A93, label 11/600.
    final color = active ? FigmaPalette.primary : FigmaPalette.navInactive;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _IconWithBadge(icon: icon, color: color, count: badgeCount),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Nav icon with an optional unread badge pinned to its top-right corner.
class _IconWithBadge extends StatelessWidget {
  const _IconWithBadge({
    required this.icon,
    required this.color,
    required this.count,
  });

  final IconData icon;
  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    final icon0 = Icon(icon, size: 20, color: color);
    if (count <= 0) return icon0;

    final label = count > 99 ? '99+' : '$count';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon0,
        Positioned(
          top: -5,
          right: -7,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(minWidth: 16),
            height: 16,
            decoration: BoxDecoration(
              color: FigmaPalette.unreadDot,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                height: 1,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CenterFab extends StatelessWidget {
  const _CenterFab({
    required this.active,
    required this.icon,
    required this.onTap,
  });

  final bool active;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Figma: 64×64 #004EEB circle, shadow 0 6 10 rgba(0,41,122,0.2).
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x3300297A), // rgba(0,41,122,0.2)
            offset: Offset(0, 6),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: FigmaPalette.primary,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: FloatingMarketNav._fabSize,
            height: FloatingMarketNav._fabSize,
            // Carrier: magnet (Magnit); shipper/broker: plus (post a load).
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
