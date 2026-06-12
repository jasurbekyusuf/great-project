import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/shared/widgets/floating_market_nav.dart';
import 'package:loadme_mobile/shared/widgets/mobile_auth_required_sheet.dart';

/// Hosts the bottom navigation bar and a [StatefulNavigationShell] body.
///
/// Visual: [FloatingMarketNav] (Figma `Nav_bar`, frame 6435:34667) — a
/// floating white pill with 4 standard tabs and a raised centre FAB. Identical
/// look in authed shell and guest mode (see `MarketScreen`).
///
/// Branch ↔ nav mapping:
///   ┌─────────────────┬──────────┬──────────────┐
///   │ Nav visual slot │ Nav idx  │ Shell branch │
///   ├─────────────────┼──────────┼──────────────┤
///   │ Asosiy          │ 0        │ 0 (Search)   │
///   │ Garaj           │ 1        │ 2 (My)       │
///   │ FAB (Magnit)    │ 2        │ — push       │
///   │ Xabarlar        │ 3        │ — push       │
///   │ Profil          │ 4        │ 3 (Profile)  │
///   └─────────────────┴──────────┴──────────────┘
class ScaffoldWithNav extends ConsumerWidget {
  const ScaffoldWithNav({super.key, required this.shell, this.guest = false});

  final StatefulNavigationShell shell;
  final bool guest;

  // Branch index → nav visual index
  static const _branchToNav = [0, 2, 1, 4];
  // Nav visual index → branch index (or -1 for non-branch like Xabarlar)
  static const _navToBranch = [0, 2, 1, -1, 3];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // Frosted-glass nav floats over the content, which scrolls behind it.
      extendBody: true,
      body: shell,
      bottomNavigationBar: FloatingMarketNav(
        activeIndex: _branchToNav[shell.currentIndex],
        onTap: (i) => _handleTap(context, i),
      ),
    );
  }

  void _handleTap(BuildContext context, int navIndex) {
    // Xabarlar — push the notifications screen on top of the current branch.
    if (navIndex == 3) {
      if (guest) {
        showMobileAuthRequiredSheet(context);
        return;
      }
      context.push('/notifications');
      return;
    }

    // Magnit — push the magnet alert form over the current branch.
    if (navIndex == 2) {
      if (guest) {
        showMobileAuthRequiredSheet(context);
        return;
      }
      context.push('/magnit');
      return;
    }

    final targetBranch = _navToBranch[navIndex];
    if (targetBranch < 0) return;

    // Guest mode can only use Asosiy (branch 0 = Search).
    if (guest && targetBranch != 0) {
      showMobileAuthRequiredSheet(context);
      return;
    }

    shell.goBranch(
      targetBranch,
      initialLocation: targetBranch == shell.currentIndex,
    );
  }
}
