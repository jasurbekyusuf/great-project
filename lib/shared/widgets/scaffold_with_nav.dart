import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/features/auth/presentation/providers/current_user_provider.dart';
import 'package:loadme_mobile/shared/widgets/floating_market_nav.dart';
import 'package:loadme_mobile/shared/widgets/mobile_auth_required_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The nav slot shown as an overlay over the shell — Xabarlar (3) or Magnit
/// (2). Those routes are pushed on top of the current branch instead of being
/// real shell branches, so `context.push` does not change the URL (it is
/// imperative) and the pill can't infer them from the route. We carry the
/// active overlay slot here instead: set on push, cleared on pop / branch tap.
final navOverlayProvider = StateProvider<int?>((ref) => null);

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
    // An open Xabarlar/Magnit overlay wins the highlight; otherwise fall back
    // to the active shell branch.
    final overlay = ref.watch(navOverlayProvider);
    final isCarrier = ref.watch(currentUserRoleSyncProvider) == 'carrier';
    return Scaffold(
      // Frosted-glass nav floats over the content, which scrolls behind it.
      extendBody: true,
      body: shell,
      bottomNavigationBar: FloatingMarketNav(
        activeIndex: overlay ?? _branchToNav[shell.currentIndex],
        // Carrier: Garaj + magnet (Magnit). Shipper/broker: Yuklarim + plus.
        secondLabel: isCarrier ? 'Garaj' : 'Yuklarim',
        secondIcon: isCarrier ? LucideIcons.warehouse : LucideIcons.package,
        fabIcon: isCarrier ? LucideIcons.magnet : LucideIcons.plus,
        onTap: (i) => unawaited(_handleTap(context, ref, i)),
      ),
    );
  }

  Future<void> _handleTap(
    BuildContext context,
    WidgetRef ref,
    int navIndex,
  ) async {
    final overlay = ref.read(navOverlayProvider.notifier);

    // Xabarlar — push the notifications screen on top of the current branch.
    if (navIndex == 3) {
      if (guest) {
        unawaited(showMobileAuthRequiredSheet(context));
        return;
      }
      if (ref.read(navOverlayProvider) == 3) return; // already open
      overlay.state = 3;
      await context.push('/notifications');
      // `push` completes when the route is popped (back / swipe) — restore the
      // branch highlight, unless another overlay opened meanwhile.
      if (ref.read(navOverlayProvider) == 3) overlay.state = null;
      return;
    }

    final isCarrier = ref.read(currentUserRoleSyncProvider) == 'carrier';

    // Centre FAB — carrier: Magnit alert form; shipper/broker: post a load.
    if (navIndex == 2) {
      if (guest) {
        unawaited(showMobileAuthRequiredSheet(context));
        return;
      }
      overlay.state = 2;
      await context.push(isCarrier ? '/magnit' : '/add-load');
      if (ref.read(navOverlayProvider) == 2) overlay.state = null;
      return;
    }

    final targetBranch = _navToBranch[navIndex];
    if (targetBranch < 0) return;

    // Guest mode can only use Asosiy (branch 0 = Search).
    if (guest && targetBranch != 0) {
      unawaited(showMobileAuthRequiredSheet(context));
      return;
    }

    // Switching to a real branch clears any overlay highlight.
    overlay.state = null;

    // Role-aware landing for shipper/broker: Asosiy → trucks search,
    // Yuklarim → My loads. Carriers keep loads search + Garaj via goBranch.
    if (!isCarrier && (targetBranch == 0 || targetBranch == 2)) {
      if (context.mounted) {
        context.go(targetBranch == 0 ? '/trucks' : '/my-loads');
      }
      return;
    }
    shell.goBranch(
      targetBranch,
      initialLocation: targetBranch == shell.currentIndex,
    );
  }
}
