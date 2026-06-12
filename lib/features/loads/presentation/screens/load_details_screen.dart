import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/core/utils/address_format.dart';
import 'package:loadme_mobile/features/loads/domain/entities/load_entity.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_controller.dart';
import 'package:loadme_mobile/shared/design_system/ds_confirmation_modal.dart';
import 'package:loadme_mobile/shared/design_system/ds_error_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_loader.dart';
import 'package:loadme_mobile/shared/widgets/app_svg_icon.dart';
import 'package:loadme_mobile/shared/widgets/load_card_parts.dart';
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

class _Header extends StatelessWidget {
  const _Header({
    required this.ownerMode,
    required this.isActive,
    required this.onEdit,
  });

  final bool ownerMode;
  final bool isActive;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final canEdit = ownerMode && isActive;
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
                    'Details',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: FigmaPalette.ink,
                    ),
                  ),
                ),
                _CircleBtn(
                  icon: canEdit ? LucideIcons.squarePen : LucideIcons.bookmark,
                  onTap: canEdit ? onEdit : () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, size: 22, color: FigmaPalette.ink),
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
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              _RouteCard(load: load),
              const SizedBox(height: 8),
              const _DetailsCard(),
              const SizedBox(height: 8),
              _MapCard(load: load),
              const SizedBox(height: 8),
              const _OwnerCard(),
            ],
          ),
        ),
        _BottomBar(
          ownerMode: ownerMode,
          isActive: isActive,
          onArchiveToggle: () => _ownerToggle(context, ref),
          onEdit: () => context.push('/edit-load/${load.guid}'),
        ),
      ],
    );
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
          content: Text(isActive ? 'Yuk arxivlandi' : 'Qayta faollashtirildi')));
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
                      region:
                          addressRegion(load.fromAddress, 'Qashqadaryo, UZB'),
                      date: '4-iyun',
                    ),
                    const SizedBox(height: 8),
                    _stopText(
                      city: addressCity(load.toAddress),
                      region: addressRegion(load.toAddress, 'Kamchatka, RUS'),
                      date: '8-iyun',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Naqd / Avans price box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: FigmaPalette.chipBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _money(
                      'Naqd', '220 000 000 so’m', FigmaPalette.moneyGreen),
                ),
                Container(
                    width: 1, height: 28, color: FigmaPalette.dividerStrong),
                const SizedBox(width: 12),
                Expanded(
                  child: _money(
                      'Avans', '30 000 000 so’m', FigmaPalette.gray700),
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
                fontSize: 12,
                height: 20 / 12,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: FigmaPalette.gray700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Details card (spec rows + Izoh)
// ---------------------------------------------------------------------------

class _DetailsCard extends StatelessWidget {
  const _DetailsCard();

  static const _rows = <(IconData, String, String)>[
    (LucideIcons.snowflake, 'Transport turi:', 'Refer'),
    (LucideIcons.thermometer, 'Harorat:', '-2°  +12°'),
    (LucideIcons.package, 'Mahsulot:', 'Gilos'),
    (LucideIcons.arrowDownToLine, 'Yuklash turi:', 'Dagruz (To’liq)'),
    (LucideIcons.mapPin, 'Radius (Yukgacha):', '10 km'),
    (LucideIcons.route, 'Masofa:', '400 km'),
    (LucideIcons.weight, 'Og’irlik:', '4 t'),
    (LucideIcons.box, 'Yuk hajmi:', '-'),
  ];

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final r in _rows) _row(r.$1, r.$2, r.$3),
          const SizedBox(height: 8),
          const Divider(
              height: 1, thickness: 1, color: FigmaPalette.dividerStrong),
          const SizedBox(height: 12),
          const Text(
            'Izoh:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: FigmaPalette.label,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Temperature inside truck may depend on the weather outside',
            style: TextStyle(
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

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: FigmaPalette.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: FigmaPalette.gray700,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: FigmaPalette.ink,
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
                from: cityLatLng(addressCity(load.fromAddress)),
                to: cityLatLng(addressCity(load.toAddress)),
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
  const _OwnerCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + rating | role badge
          Row(
            children: [
              appSvgIcon('card_verified', size: 16),
              const SizedBox(width: 6),
              const Text(
                'ExportView LTD',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: FigmaPalette.ink,
                ),
              ),
              const SizedBox(width: 6),
              const Text('4.5',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: FigmaPalette.ink)),
              const SizedBox(width: 2),
              appSvgIcon('card_star', size: 14),
              const Spacer(),
              const RoleBadge(label: 'Yuk egasi'),
            ],
          ),
          const SizedBox(height: 12),
          _contact(LucideIcons.send, 'Telegram', '@calltome'),
          const SizedBox(height: 8),
          _contact(LucideIcons.phone, 'Whatsapp', '@callmexport'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _OutlineBtn(
                  icon: LucideIcons.star,
                  label: 'Baholash',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _OutlineBtn(
                  icon: LucideIcons.flag,
                  label: 'Shikoyat qilish',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contact(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: FigmaPalette.primary),
        const SizedBox(width: 8),
        Text('$label:',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: FigmaPalette.gray700)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: FigmaPalette.ink)),
      ],
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FigmaPalette.dividerStrong),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: FigmaPalette.tertiary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: FigmaPalette.tertiary,
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
// Sticky bottom CTA
// ---------------------------------------------------------------------------

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.ownerMode,
    required this.isActive,
    required this.onArchiveToggle,
    required this.onEdit,
  });

  final bool ownerMode;
  final bool isActive;
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
                  onTap: () {},
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
