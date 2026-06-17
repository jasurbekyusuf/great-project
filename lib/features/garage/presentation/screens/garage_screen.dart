import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/features/garage/presentation/providers/garage_providers.dart';
import 'package:loadme_mobile/features/garage/presentation/widgets/garage_route_card.dart';
import 'package:loadme_mobile/features/garage/presentation/widgets/garage_vehicle_card.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';
import 'package:loadme_mobile/shared/design_system/ds_confirmation_modal.dart';
import 'package:loadme_mobile/shared/design_system/ds_empty_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_error_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_loader.dart';
import 'package:loadme_mobile/shared/widgets/app_svg_icon.dart';
import 'package:loadme_mobile/shared/widgets/card_action_menu.dart';
import 'package:loadme_mobile/shared/widgets/floating_market_nav.dart';
import 'package:loadme_mobile/shared/widgets/frosted_header.dart';
import 'package:loadme_mobile/shared/widgets/mobile_segmented_tab.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Figma "Garaj" (nodes 6593-19490 / 6602-20760): two tabs — the carrier's
/// vehicles (Transportlar) and their saved routes (Yo'nalishlarim) — with a
/// sticky "add" CTA that clears the floating bottom nav.
class GarageScreen extends ConsumerStatefulWidget {
  const GarageScreen({super.key});

  @override
  ConsumerState<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends ConsumerState<GarageScreen> {
  int _tab = 0; // 0 = Transportlar, 1 = Yo'nalishlarim

  @override
  Widget build(BuildContext context) {
    // Lift the sticky CTA clear of the floating nav + raised FAB, plus a gap.
    final navClearance = MediaQuery.viewPaddingOf(context).bottom +
        FloatingMarketNav.reservedHeight +
        24;

    // On the empty state the illustration shows its own "Qo'shish" button
    // (Figma 6542:41936), so hide the sticky CTA there.
    final activeEmpty = _tab == 0
        ? (ref.watch(garageVehiclesProvider).valueOrNull?.isEmpty ?? false)
        : (ref.watch(garageRoutesProvider).valueOrNull?.isEmpty ?? false);

    return Scaffold(
      backgroundColor: FigmaPalette.sheetBg,
      body: Column(
        children: [
          FrostedHeader(
            title: 'garage.title'.tr(ref),
            bottom: MobileSegmentedTab(
              items: [
                'garage.tab.transports'.tr(ref),
                'garage.tab.routes'.tr(ref),
              ],
              selectedIndex: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _tab == 0
                  ? const _TransportsList(key: ValueKey('transports'))
                  : const _RoutesList(key: ValueKey('routes')),
            ),
          ),
          if (!activeEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, navClearance),
              child: DsButton(
                label: (_tab == 0 ? 'garage.addTransport' : 'garage.addRoute')
                    .tr(ref),
                icon: Icons.add,
                onPressed: () =>
                    context.push(_tab == 0 ? '/add-truck' : '/magnit'),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Transportlar — vehicle cards
// ---------------------------------------------------------------------------
class _TransportsList extends ConsumerWidget {
  const _TransportsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(garageVehiclesProvider).when(
          loading: () => const DsLoader(),
          error: (e, _) => DsErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(garageVehiclesProvider),
          ),
          data: (vehicles) {
            if (vehicles.isEmpty) {
              return DsEmptyState(
                title: 'garage.empty.transports'.tr(ref),
                // Figma "New design" empty (node 6782:11096): 199x168 3D
                // illustration exported at 4x (PNG includes a ~16px shadow
                // halo → 231x200 keeps the core art at 199x168).
                icon: Image.asset(
                  'assets/images/empty_garage.png',
                  width: 231,
                  height: 200,
                  fit: BoxFit.contain,
                ),
                actionLabel: 'common.add'.tr(ref),
                onAction: () => context.push('/add-truck'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: vehicles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, i) {
                final v = vehicles[i];
                return GarageVehicleCard(
                  name: v.name,
                  model: v.model,
                  plate: v.plate,
                  photoUrl: v.photoUrl,
                  onEdit: () => context.push('/edit-truck/${v.id}'),
                  onTap: () => context.push('/transport/${v.id}'),
                );
              },
            );
          },
        );
  }
}

// ---------------------------------------------------------------------------
// Yo'nalishlarim — route cards
// ---------------------------------------------------------------------------
class _RoutesList extends ConsumerWidget {
  const _RoutesList({super.key});

  Future<void> _confirmArchive(
      BuildContext context, WidgetRef ref, GarageRoute r) async {
    final ok = await showDsConfirmation(
      context,
      title: 'owner.archive'.tr(ref),
      message: 'owner.archiveMessage'.tr(ref),
      confirmText: 'owner.archive'.tr(ref),
      cancelText: 'common.cancel'.tr(ref),
      intent: DsConfirmIntent.warning,
      icon: Icons.inventory_2_outlined,
    );
    if (!ok) return;
    // Demo seed is read-only for archiving; pausing keeps it visible here.
    if (r.active) {
      await ref.read(garageRoutesProvider.notifier).toggleActive(r.id);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, GarageRoute r) async {
    final ok = await showDsConfirmation(
      context,
      title: 'common.delete'.tr(ref),
      message: 'owner.archiveMessage'.tr(ref),
      confirmText: 'common.delete'.tr(ref),
      cancelText: 'common.cancel'.tr(ref),
      intent: DsConfirmIntent.warning,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok) return;
    await ref.read(garageRoutesProvider.notifier).remove(r.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(garageRoutesProvider).when(
          loading: () => const DsLoader(),
          error: (e, _) => DsErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(garageRoutesProvider),
          ),
          data: (routes) {
            if (routes.isEmpty) {
              return DsEmptyState(
                title: 'garage.empty.routes'.tr(ref),
                icon: appSvgIcon('empty_truck', size: 84),
                actionLabel: 'common.add'.tr(ref),
                onAction: () => context.push('/magnit'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: routes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, i) {
                final r = routes[i];
                return GarageRouteCard(
                  name: r.name,
                  priceLabel: r.priceLabel,
                  fromCity: r.fromCity,
                  fromCountry: r.fromCountry,
                  toCity: r.toCity,
                  toCountry: r.toCountry,
                  distanceKm: r.distanceKm,
                  weightT: r.weightT,
                  loadKind: r.loadKind,
                  active: r.active,
                  avatarUrl: r.avatarUrl,
                  onToggle: (_) =>
                      ref.read(garageRoutesProvider.notifier).toggleActive(r.id),
                  menuActions: [
                    CardMenuAction(
                      icon: LucideIcons.pencil,
                      label: 'common.edit'.tr(ref),
                      onSelected: () => context.push('/edit-post-truck/${r.id}'),
                    ),
                    CardMenuAction(
                      icon: LucideIcons.archive,
                      label: 'owner.archive'.tr(ref),
                      onSelected: () => _confirmArchive(context, ref, r),
                    ),
                    CardMenuAction(
                      icon: LucideIcons.trash2,
                      label: 'common.delete'.tr(ref),
                      destructive: true,
                      onSelected: () => _confirmDelete(context, ref, r),
                    ),
                  ],
                );
              },
            );
          },
        );
  }
}
