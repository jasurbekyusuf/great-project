import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
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
class FloatingMarketNav extends StatelessWidget {
  const FloatingMarketNav({
    super.key,
    required this.activeIndex,
    required this.onTap,
  });

  /// 0..4 (Asosiy, Garaj, FAB, Xabarlar, Profil) or null for nothing active.
  final int? activeIndex;

  /// Called with the tapped nav index (0..4).
  final ValueChanged<int> onTap;

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
  Widget build(BuildContext context) {
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
                                label: 'Asosiy',
                                icon: LucideIcons.search,
                                active: activeIndex == 0,
                                onTap: () => onTap(0),
                              ),
                            ),
                            Expanded(
                              child: _NavSlot(
                                label: 'Garaj',
                                icon: LucideIcons.warehouse,
                                active: activeIndex == 1,
                                onTap: () => onTap(1),
                              ),
                            ),
                            // Reserve the centre slot for the raised FAB.
                            const SizedBox(width: _fabSize),
                            Expanded(
                              child: _NavSlot(
                                label: 'Xabarlar',
                                icon: LucideIcons.bell,
                                active: activeIndex == 3,
                                onTap: () => onTap(3),
                              ),
                            ),
                            Expanded(
                              child: _NavSlot(
                                label: 'Profil',
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
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

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
          Icon(icon, size: 20, color: color),
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

class _CenterFab extends StatelessWidget {
  const _CenterFab({required this.active, required this.onTap});

  final bool active;
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
          child: const SizedBox(
            width: FloatingMarketNav._fabSize,
            height: FloatingMarketNav._fabSize,
            // Magnet icon (lucide) — matches the Figma centre FAB illustration.
            child: Icon(LucideIcons.magnet, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
