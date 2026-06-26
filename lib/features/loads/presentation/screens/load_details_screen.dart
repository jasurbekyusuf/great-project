import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/core/utils/address_format.dart';
import 'package:loadme_mobile/core/utils/phone_launcher.dart';
import 'package:loadme_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:loadme_mobile/features/loads/domain/entities/load_entity.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_controller.dart';
import 'package:loadme_mobile/features/saved/presentation/providers/saved_providers.dart';
import 'package:loadme_mobile/shared/design_system/ds_confirmation_modal.dart';
import 'package:loadme_mobile/shared/design_system/ds_error_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_info_modal.dart';
import 'package:loadme_mobile/shared/design_system/ds_loader.dart';
import 'package:loadme_mobile/shared/widgets/app_svg_icon.dart';
import 'package:loadme_mobile/shared/widgets/load_card_parts.dart';
import 'package:loadme_mobile/shared/widgets/mobile_auth_required_sheet.dart';
import 'package:loadme_mobile/shared/widgets/route_map.dart';
import 'package:loadme_mobile/shared/widgets/swipe_back_wrapper.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Pixel port of the Figma "Search/details" frame (node 6435:39895).
//   • bg #F3F4F7, white cards r18 / pad16, 8px gaps
//   • route card (cube→flag, dates) + Naqd/Avans price box
//   • spec rows (icon · label · value) + Izoh
//   • map preview card + owner card
//   • sticky "Bog'lanish" CTA
class LoadDetailsScreen extends ConsumerWidget {
  const LoadDetailsScreen({
    super.key,
    required this.id,
    this.ownerMode = false,
    this.isActive = true,
  });

  final String id;
  final bool ownerMode;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loadDetailsProvider(id));

    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: FigmaPalette.sheetBg,
        body: Column(
          children: [
            _Header(
              id: id,
              ownerMode: ownerMode,
              isActive: isActive,
              onEdit: () => context.push('/edit-load/$id'),
            ),
            Expanded(
              child: state.when(
                loading: () => const DsLoader(),
                error: (e, _) => DsErrorState(message: e.toString()),
                data: (load) => _Body(
                  load: load,
                  ownerMode: ownerMode,
                  isActive: isActive,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header — back · "Details" · bookmark / edit
// ---------------------------------------------------------------------------

class _Header extends ConsumerWidget {
  const _Header({
    required this.id,
    required this.ownerMode,
    required this.isActive,
    required this.onEdit,
  });

  final String id;
  final bool ownerMode;
  final bool isActive;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEdit = ownerMode && isActive;
    // The bookmark saves a load you're browsing — owners (who instead get the
    // edit pen, or view their own archived load) don't save their own loads.
    final showSave = !ownerMode;
    final isGuest = ref.watch(authControllerProvider).valueOrNull == null;
    final isSaved = showSave &&
        !isGuest &&
        (ref.watch(savedControllerProvider).valueOrNull?.any(
              (s) => s.id == id || s.load.guid == id,
            ) ??
            false);

    final IconData trailingIcon;
    final Color trailingColor;
    final VoidCallback onTrailing;
    if (canEdit) {
      trailingIcon = LucideIcons.squarePen;
      trailingColor = FigmaPalette.ink;
      onTrailing = onEdit;
    } else if (showSave) {
      // Saved → filled bookmark (no text feedback; the icon carries the state).
      trailingIcon = isSaved ? Icons.bookmark : LucideIcons.bookmark;
      trailingColor = isSaved ? FigmaPalette.primary : FigmaPalette.ink;
      onTrailing = () =>
          _toggleSave(context, ref, isSaved: isSaved, isGuest: isGuest);
    } else {
      // Owner viewing an archived load — bookmark placeholder (inert).
      trailingIcon = LucideIcons.bookmark;
      trailingColor = FigmaPalette.ink;
      onTrailing = () {};
    }

    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _CircleBtn(
                  icon: LucideIcons.chevronLeft,
                  // go_router pop when possible; otherwise (deep-link entry)
                  // fall back to the list (redirects to /guest if not authed).
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/loads'),
                ),
                const Expanded(
                  child: Text(
                    'Yuk ma’lumotlari',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: FigmaPalette.ink,
                    ),
                  ),
                ),
                _CircleBtn(
                  icon: trailingIcon,
                  color: trailingColor,
                  onTap: onTrailing,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Toggles the favorite for this load. Guests get the auth prompt; authed
  /// users get an optimistic save/un-save — the bookmark icon flips to its
  /// filled/active state, so there's no success snackbar. Only failures surface
  /// a message.
  Future<void> _toggleSave(
    BuildContext context,
    WidgetRef ref, {
    required bool isSaved,
    required bool isGuest,
  }) async {
    if (isGuest) {
      unawaited(showMobileAuthRequiredSheet(context));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(savedControllerProvider.notifier);
    final failure =
        isSaved ? await notifier.removeByLoad(id) : await notifier.add(id);
    if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({
    required this.icon,
    required this.onTap,
    this.color = FigmaPalette.ink,
  });
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _Body extends ConsumerWidget {
  const _Body({
    required this.load,
    required this.ownerMode,
    required this.isActive,
  });
  final LoadEntity load;
  final bool ownerMode;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // No session → guest. Tapping "Bog'lanish" then opens the login prompt
    // instead of the (authed-only) contact action.
    final isGuest = ref.watch(authControllerProvider).valueOrNull == null;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              _RouteCard(load: load),
              const SizedBox(height: 8),
              _DetailsCard(load: load),
              const SizedBox(height: 8),
              _MapCard(load: load),
              const SizedBox(height: 8),
              _OwnerCard(load: load),
            ],
          ),
        ),
        _BottomBar(
          ownerMode: ownerMode,
          isActive: isActive,
          onContact: () {
            if (isGuest) {
              unawaited(showMobileAuthRequiredSheet(context));
              return;
            }
            // Authed → hand off to the native dialer with the owner's number.
            unawaited(_contactByPhone(context));
          },
          onArchiveToggle: () => _ownerToggle(context, ref),
          onEdit: () => context.push('/edit-load/${load.guid}'),
        ),
      ],
    );
  }

  /// Opens the dialer for the load owner's phone. A missing number surfaces a
  /// short notice instead of failing silently.
  Future<void> _contactByPhone(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchPhoneDial(load.phone);
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Telefon raqami mavjud emas')),
      );
    }
  }

  Future<void> _ownerToggle(BuildContext context, WidgetRef ref) async {
    final confirm = await showDsConfirmation(
      context,
      title: (isActive ? 'detail.archiveLoad' : 'detail.reactivate').tr(ref),
      message:
          (isActive ? 'detail.archiveLoadMessage' : 'detail.reactivateMessage')
              .tr(ref),
      confirmText: (isActive ? 'owner.archive' : 'detail.reactivate').tr(ref),
      cancelText: 'common.cancel'.tr(ref),
      intent: isActive ? DsConfirmIntent.warning : DsConfirmIntent.primary,
      icon: isActive ? Icons.inventory_2_outlined : Icons.refresh_rounded,
    );
    if (!confirm || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref.read(myLoadsControllerProvider.notifier).updateStatus(
            guid: load.guid,
            isActive: !isActive,
            closedPlatform: isActive ? 'loadme' : null,
          );
      messenger.showSnackBar(SnackBar(
          content:
              Text(isActive ? 'Yuk arxivlandi' : 'Qayta faollashtirildi')));
      router.go('/my-loads');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

// ---------------------------------------------------------------------------
// Shared card shell
// ---------------------------------------------------------------------------

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Route card
// ---------------------------------------------------------------------------

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.load});
  final LoadEntity load;

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left icon column: cube · dotted · flag (parallel to the text).
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  appSvgIcon('card_cube', size: 16, color: FigmaPalette.ink),
                  const DottedConnector(height: 24),
                  appSvgIcon('card_flag', size: 16, color: FigmaPalette.ink),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _stopText(
                      city: addressCity(load.fromAddress),
                      region: addressRegion(
                          load.fromAddress, load.fromCountry ?? ''),
                      date: _uzDate(load.pickupDate) ?? '',
                    ),
                    const SizedBox(height: 8),
                    _stopText(
                      city: addressCity(load.toAddress),
                      region:
                          addressRegion(load.toAddress, load.toCountry ?? ''),
                      date: _uzDate(load.deliveryDate) ?? '',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Naqd / Avans price box — banknote chip + two money columns that hug
          // their text, split by a 1×32 hairline (Figma 270988543).
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: FigmaPalette.chipBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: FigmaPalette.paymentIconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.banknote,
                      size: 20, color: FigmaPalette.primary),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: _money(
                      'Naqd', load.priceLabel ?? '—', FigmaPalette.moneyGreen),
                ),
                const SizedBox(width: 10),
                Container(width: 1, height: 32, color: FigmaPalette.label),
                const SizedBox(width: 10),
                Flexible(
                  child: _money('Avans', '—', FigmaPalette.gray700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // One stop's text block (city + date, region) — fixed line heights so the
  // left icon column lines up: city 20px + 2 + region 18px = 40px.
  Widget _stopText({
    required String city,
    required String region,
    required String date,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                city,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w600,
                  color: FigmaPalette.inkStrong,
                ),
              ),
            ),
            Text(
              date,
              style: const TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w500,
                color: FigmaPalette.label,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          region,
          style: const TextStyle(
            fontSize: 12,
            height: 18 / 12,
            fontWeight: FontWeight.w500,
            color: FigmaPalette.label,
          ),
        ),
      ],
    );
  }

  Widget _money(String label, String value, Color valueColor) {
    // Currency token (e.g. "so’m") renders one step smaller than the amount,
    // matching the Figma per-character styling.
    final i = value.lastIndexOf(' ');
    final hasSuffix = i > 0 && i < value.length - 1;
    final amount = hasSuffix ? value.substring(0, i + 1) : value;
    final suffix = hasSuffix ? value.substring(i + 1) : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            height: 18 / 12,
            fontWeight: FontWeight.w500,
            color: FigmaPalette.gray700,
          ),
        ),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            text: amount,
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
            children: hasSuffix
                ? [TextSpan(text: suffix, style: const TextStyle(fontSize: 12))]
                : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // "2026-06-04T..." → "4-iyun" using Uzbek month names.
  String? _uzDate(String? iso) {
    if (iso == null) return null;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return null;
    const months = [
      'yanvar',
      'fevral',
      'mart',
      'aprel',
      'may',
      'iyun',
      'iyul',
      'avgust',
      'sentabr',
      'oktabr',
      'noyabr',
      'dekabr',
    ];
    return '${dt.day}-${months[dt.month - 1]}';
  }
}

// ---------------------------------------------------------------------------
// Details card (spec rows + Izoh)
// ---------------------------------------------------------------------------

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.load});
  final LoadEntity load;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(LucideIcons.truck, 'Transport turi:',
              value: load.truckType ?? '—'),
          _row(LucideIcons.forklift, 'Yuklash turi:',
              value: load.isPartial ? 'Qisman' : "To'liq"),
          _row(LucideIcons.mapPin, 'Radius (Yukgacha):',
              value: load.radiusKm != null ? '${load.radiusKm} km' : '—'),
          _row(LucideIcons.route, 'Masofa:',
              value: load.distanceKm != null ? '${load.distanceKm} km' : '—'),
          _row(LucideIcons.weight, 'Og’irlik:',
              value:
                  load.weightT != null ? '${formatQty(load.weightT!)} t' : '—'),
          _row(LucideIcons.box, 'Yuk hajmi:',
              value: load.volumeM3 != null
                  ? '${formatQty(load.volumeM3!)} m³'
                  : '—'),
          const SizedBox(height: 8),
          const Divider(
              height: 1, thickness: 1, color: FigmaPalette.dividerStrong),
          const SizedBox(height: 12),
          const Text(
            'Izoh:',
            style: TextStyle(
              fontSize: 12,
              height: 18 / 12,
              fontWeight: FontWeight.w500,
              color: FigmaPalette.label,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            load.comment ?? '—',
            style: const TextStyle(
              fontSize: 12,
              height: 18 / 12,
              fontWeight: FontWeight.w500,
              color: FigmaPalette.ink,
            ),
          ),
        ],
      ),
    );
  }

  // One spec row: gray-boxed blue icon · label and value as two equal columns
  // (Figma 1321315320 — the value left-aligns into its own column, it is *not*
  // pushed to the right edge).
  Widget _row(IconData icon, String label, {required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: FigmaPalette.chipBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: FigmaPalette.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 18 / 12,
                fontWeight: FontWeight.w500,
                color: FigmaPalette.gray700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 18 / 12,
                fontWeight: FontWeight.w500,
                color: FigmaPalette.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Map card
// ---------------------------------------------------------------------------

class _MapCard extends StatelessWidget {
  const _MapCard({required this.load});
  final LoadEntity load;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 200,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              // Live OpenStreetMap preview (non-interactive inside the card).
              RouteMap(
                from: load.pickupLat != null && load.pickupLng != null
                    ? LatLng(load.pickupLat!, load.pickupLng!)
                    : cityLatLng(addressCity(load.fromAddress)),
                to: load.deliveryLat != null && load.deliveryLng != null
                    ? LatLng(load.deliveryLat!, load.deliveryLng!)
                    : cityLatLng(addressCity(load.toAddress)),
                interactive: false,
              ),
              // "Show in map" pill — wrapped in Center so the white Container
              // sizes to its content instead of expanding (StackFit.expand)
              // and painting over the whole map.
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A101828),
                        offset: Offset(0, 2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.map,
                          size: 18, color: FigmaPalette.primary),
                      SizedBox(width: 8),
                      Text(
                        'Show in map',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Owner card
// ---------------------------------------------------------------------------

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({required this.load});
  final LoadEntity load;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + rating | role badge
          Row(
            children: [
              if (load.verified) ...[
                appSvgIcon('card_verified', size: 16),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  load.ownerName ?? 'LoadMe',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 18 / 14,
                    fontWeight: FontWeight.w500,
                    color: FigmaPalette.ink,
                  ),
                ),
              ),
              if (load.ownerRating != null) ...[
                const SizedBox(width: 6),
                Text(load.ownerRating!.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 14,
                        height: 18 / 14,
                        fontWeight: FontWeight.w500,
                        color: FigmaPalette.ink)),
                const SizedBox(width: 2),
                appSvgIcon('card_star', size: 14),
              ],
              const Spacer(),
              if (load.roleBadge != null) RoleBadge(label: load.roleBadge!),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _contactCol('Telegram:', load.telegram ?? '—')),
              const SizedBox(width: 12),
              Expanded(child: _contactCol('Whatsapp:', load.whatsapp ?? '—')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionChip(
                  icon: LucideIcons.star,
                  label: 'Baholash',
                  onTap: () => unawaited(
                    showContactGateModal(context, DsContactGate.rate),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionChip(
                  icon: LucideIcons.scrollText,
                  label: 'Shikoyat qilish',
                  onTap: () => unawaited(
                    showContactGateModal(context, DsContactGate.report),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Figma owner card: Telegram / Whatsapp sit side by side as label-over-value
  // columns (gray label, blue value, no leading icon) — same as the transport
  // detail contact block.
  Widget _contactCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: FigmaPalette.label)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: FigmaPalette.primary)),
      ],
    );
  }
}

// Gray-filled pill (Figma 1321315331 / 1711112378) — a 16px icon + 12/500
// label on the neutral chip background. Used for the Baholash / Shikoyat
// owner-card actions.
class _ActionChip extends StatelessWidget {
  const _ActionChip(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FigmaPalette.chipBg,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 32,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: FigmaPalette.gray700),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 18 / 12,
                    fontWeight: FontWeight.w500,
                    color: FigmaPalette.gray700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sticky bottom CTA
// ---------------------------------------------------------------------------

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.ownerMode,
    required this.isActive,
    required this.onContact,
    required this.onArchiveToggle,
    required this.onEdit,
  });

  final bool ownerMode;
  final bool isActive;
  final VoidCallback onContact;
  final VoidCallback onArchiveToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: ownerMode
              ? Row(
                  children: [
                    Expanded(
                      child: _SolidBtn(
                        label: isActive ? 'Arxivlash' : 'Faollashtirish',
                        color: isActive
                            ? FigmaPalette.dangerText
                            : FigmaPalette.primary,
                        onTap: onArchiveToggle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SolidBtn(
                        label: 'Tahrirlash',
                        color: FigmaPalette.primary,
                        onTap: onEdit,
                      ),
                    ),
                  ],
                )
              : _SolidBtn(
                  label: 'Bog’lanish',
                  color: FigmaPalette.primary,
                  onTap: onContact,
                ),
        ),
      ),
    );
  }
}

class _SolidBtn extends StatelessWidget {
  const _SolidBtn(
      {required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
