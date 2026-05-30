import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/loads/domain/entities/load_entity.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_controller.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';
import 'package:loadme_mobile/shared/design_system/ds_card.dart';
import 'package:loadme_mobile/shared/design_system/ds_confirmation_modal.dart';
import 'package:loadme_mobile/shared/design_system/ds_error_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_loader.dart';
import 'package:loadme_mobile/shared/widgets/lightbox_image.dart';
import 'package:loadme_mobile/shared/widgets/mobile_page_head.dart';
import 'package:loadme_mobile/shared/widgets/phone_reveal.dart';
import 'package:loadme_mobile/shared/widgets/swipe_back_wrapper.dart';

// Mirrors web `Load` / `MyLoad` modules. Visible to authed shipper/broker users
// as a read-only detail; the same screen with `ownerMode: true` shows
// archive/edit and skips the contact reveal.
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
    final c = context.colors;

    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: c.background,
        body: Column(
          children: [
            MobilePageHead(
              title: (ownerMode ? 'detail.load.ownerTitle' : 'detail.load.title').tr(ref),
              trailing: ownerMode && isActive
                  ? IconButton(
                      onPressed: () => context.push('/edit-load/$id'),
                      icon: Icon(Icons.edit_outlined, size: 22, color: c.primary),
                    )
                  : IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.bookmark_outline_rounded, color: c.textPrimary),
                    ),
            ),
            Expanded(
              child: state.when(
                loading: () => const DsLoader(),
                error: (e, _) => DsErrorState(message: e.toString()),
                data: (load) => _Body(load: load, ownerMode: ownerMode, isActive: isActive),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.load, required this.ownerMode, required this.isActive});
  final LoadEntity load;
  final bool ownerMode;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.space;
    final t = context.types;

    return ListView(
      padding: EdgeInsets.fromLTRB(s.lg, s.lg, s.lg, s.xl),
      children: [
        if (!ownerMode) _OwnerCard(),
        if (!ownerMode) SizedBox(height: s.md),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('detail.section.route'.tr(ref), style: t.h3),
              SizedBox(height: s.md),
              _RouteBlock(from: load.fromAddress, to: load.toAddress, fromDate: load.pickupDate),
            ],
          ),
        ),
        SizedBox(height: s.md),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('detail.section.loadInfo'.tr(ref), style: t.h3),
              SizedBox(height: s.md),
              _Grid(items: [
                ('detail.field.truckType'.tr(ref), 'Tent / Shtora'),
                ('common.price'.tr(ref), load.price == null ? 'common.negotiable'.tr(ref) : '${load.price!.toStringAsFixed(0)} UZS'),
                ('detail.field.weight'.tr(ref), '20 ${'common.tons'.tr(ref)}'),
                ('detail.field.volume'.tr(ref), '100 ${'common.m3'.tr(ref)}'),
                ('detail.field.distance'.tr(ref), '334 ${'common.km'.tr(ref)}'),
                ('detail.field.payment'.tr(ref), 'Naqd'),
              ]),
            ],
          ),
        ),
        SizedBox(height: s.md),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('detail.section.comment'.tr(ref), style: t.h3),
              SizedBox(height: s.md),
              Text(
                load.comment?.isNotEmpty == true ? load.comment! : 'detail.noComment'.tr(ref),
                style: t.body.copyWith(height: 22 / 14),
              ),
            ],
          ),
        ),
        SizedBox(height: s.md),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('detail.section.photos'.tr(ref), style: t.h3),
              SizedBox(height: s.md),
              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => LightboxImage(
                    imageUrl: 'https://picsum.photos/seed/load-${load.guid}-$i/240/240',
                    heroTag: 'load-${load.guid}-$i',
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

        if (ownerMode) ...[
          DsButton(
            label: (isActive ? 'detail.archiveLoad' : 'detail.reactivate').tr(ref),
            variant: isActive ? DsButtonVariant.outline : DsButtonVariant.solid,
            onPressed: () => _ownerToggle(context, ref),
          ),
          SizedBox(height: s.sm),
          DsButton(
            label: 'detail.editLoad'.tr(ref),
            variant: DsButtonVariant.secondary,
            onPressed: () => context.push('/edit-load/${load.guid}'),
          ),
        ] else ...[
          PhoneReveal(
            phone: '+998901234567',
            label: 'phone.show'.tr(ref),
            callLabel: 'phone.call'.tr(ref),
            onRevealed: () {},
            onCall: (_) {},
          ),
          SizedBox(height: s.sm),
          Row(
            children: [
              Expanded(
                child: DsButton(
                  label: 'detail.report'.tr(ref),
                  variant: DsButtonVariant.report,
                  icon: Icons.flag_outlined,
                  onPressed: () {},
                ),
              ),
              SizedBox(width: s.sm),
              Expanded(
                child: DsButton(
                  label: 'detail.rating'.tr(ref),
                  variant: DsButtonVariant.outline,
                  icon: Icons.star_outline_rounded,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _ownerToggle(BuildContext context, WidgetRef ref) async {
    final confirm = await showDsConfirmation(
      context,
      title: (isActive ? 'detail.archiveLoad' : 'detail.reactivate').tr(ref),
      message: (isActive ? 'detail.archiveLoadMessage' : 'detail.reactivateMessage').tr(ref),
      confirmText: (isActive ? 'owner.archive' : 'detail.reactivate').tr(ref),
      cancelText: 'common.cancel'.tr(ref),
      intent: isActive ? DsConfirmIntent.warning : DsConfirmIntent.primary,
      icon: isActive ? Icons.inventory_2_outlined : Icons.refresh_rounded,
    );
    if (!confirm) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref.read(myLoadsControllerProvider.notifier).updateStatus(
            guid: load.guid,
            isActive: !isActive,
            closedPlatform: isActive ? 'loadme' : null,
          );
      messenger.showSnackBar(SnackBar(content: Text(isActive ? 'Yuk arxivlandi' : 'Yuk qayta faollashtirildi')));
      router.go('/my-loads');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class _OwnerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.types;
    return DsCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: c.primary50,
            child: Text('LM', style: t.button.copyWith(color: c.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text('LoadMe admin', style: t.bodySemibold, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 6),
                    Icon(Icons.verified_rounded, size: 16, color: c.primary),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: c.warning300),
                    const SizedBox(width: 2),
                    Text('5.0', style: t.caption),
                    const SizedBox(width: 10),
                    Text('12 ta yuk', style: t.caption.copyWith(color: c.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteBlock extends StatelessWidget {
  const _RouteBlock({required this.from, required this.to, required this.fromDate});
  final String from;
  final String to;
  final String? fromDate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.types;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle)),
              const SizedBox(height: 2),
              SizedBox(width: 2, height: 32, child: DecoratedBox(decoration: BoxDecoration(color: c.gray300))),
              const SizedBox(height: 2),
              Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.primary, width: 2))),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(from, style: t.bodyLgMedium),
              const SizedBox(height: 4),
              if (fromDate != null) Text(fromDate!, style: t.caption.copyWith(color: c.textMuted)),
              const SizedBox(height: 18),
              Text(to, style: t.bodyLgMedium),
            ],
          ),
        ),
      ],
    );
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
