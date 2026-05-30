import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/trucks/presentation/controllers/trucks_controller.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';
import 'package:loadme_mobile/shared/design_system/ds_card.dart';
import 'package:loadme_mobile/shared/design_system/ds_confirmation_modal.dart';
import 'package:loadme_mobile/shared/design_system/ds_error_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_loader.dart';
import 'package:loadme_mobile/shared/widgets/lightbox_image.dart';
import 'package:loadme_mobile/shared/widgets/mobile_page_head.dart';
import 'package:loadme_mobile/shared/widgets/swipe_back_wrapper.dart';

// Mirrors web `MyTruck` module — fleet vehicle owner detail (not a posted load
// offer). Owner can edit / archive.
class MyTruckDetailScreen extends ConsumerWidget {
  const MyTruckDetailScreen({super.key, required this.id, this.isActive = true});

  final String id;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(truckDetailsProvider(id));
    final c = context.colors;
    final s = context.space;
    final t = context.types;

    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: c.background,
        body: Column(
          children: [
            MobilePageHead(
              title: 'detail.truck.ownerTitle'.tr(ref),
              trailing: isActive
                  ? IconButton(
                      onPressed: () => context.push('/edit-truck/$id'),
                      icon: Icon(Icons.edit_outlined, size: 22, color: c.primary),
                    )
                  : null,
            ),
            Expanded(
              child: state.when(
                loading: () => const DsLoader(),
                error: (e, _) => DsErrorState(message: e.toString()),
                data: (truck) => ListView(
                  padding: EdgeInsets.fromLTRB(s.lg, s.lg, s.lg, s.xl),
                  children: [
                    DsCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('detail.section.basic'.tr(ref), style: t.h3),
                          SizedBox(height: s.md),
                          _Grid(items: [
                            ('detail.field.model'.tr(ref), truck.modelName),
                            ('detail.field.truckType'.tr(ref), truck.truckType ?? '-'),
                            ('detail.field.capacity'.tr(ref), truck.loadCapacity ?? '-'),
                            ('detail.field.weight'.tr(ref), truck.weight ?? '-'),
                            ('detail.field.plate'.tr(ref), truck.plateNumber ?? '-'),
                            ('detail.field.trailer'.tr(ref), truck.trailerNumber ?? '-'),
                            ('detail.field.phone'.tr(ref), truck.phone ?? '-'),
                          ]),
                        ],
                      ),
                    ),
                    SizedBox(height: s.md),
                    DsCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('detail.section.certificates'.tr(ref), style: t.h3),
                          SizedBox(height: s.md),
                          SizedBox(
                            height: 88,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: 2,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (_, i) => LightboxImage(
                                imageUrl: 'https://picsum.photos/seed/cert-$id-$i/240/240',
                                heroTag: 'cert-$id-$i',
                                width: 88,
                                height: 88,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: s.lg),
                    DsButton(
                      label: (isActive ? 'owner.archive' : 'detail.reactivate').tr(ref),
                      variant: isActive ? DsButtonVariant.outline : DsButtonVariant.solid,
                      onPressed: () => _toggle(context, ref),
                    ),
                    SizedBox(height: s.sm),
                    DsButton(
                      label: 'detail.editLoad'.tr(ref),
                      variant: DsButtonVariant.secondary,
                      onPressed: () => context.push('/edit-truck/$id'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final ok = await showDsConfirmation(
      context,
      title: (isActive ? 'detail.archiveTruck' : 'detail.reactivate').tr(ref),
      message: (isActive ? 'detail.archiveTruckMessage' : 'detail.reactivateMessage').tr(ref),
      confirmText: (isActive ? 'owner.archive' : 'detail.reactivate').tr(ref),
      cancelText: 'common.cancel'.tr(ref),
      intent: isActive ? DsConfirmIntent.warning : DsConfirmIntent.primary,
      icon: isActive ? Icons.inventory_2_outlined : Icons.refresh_rounded,
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(trucksRepositoryProvider).updateTruckStatus(guid: id, isActive: !isActive);
      messenger.showSnackBar(SnackBar(content: Text(isActive ? 'Arxivlandi' : 'Faollashtirildi')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.items});
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.types;
    return Wrap(
      runSpacing: 14,
      children: items
          .map((it) => SizedBox(
                width: (MediaQuery.sizeOf(context).width - 64) / 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(it.$1, style: t.caption.copyWith(color: c.textSecondary)),
                    const SizedBox(height: 2),
                    Text(it.$2, style: t.bodyMedium),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
