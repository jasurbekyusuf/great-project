import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/trucks/presentation/controllers/trucks_controller.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';
import 'package:loadme_mobile/shared/design_system/ds_card.dart';
import 'package:loadme_mobile/shared/design_system/ds_confirmation_modal.dart';
import 'package:loadme_mobile/shared/widgets/lightbox_image.dart';
import 'package:loadme_mobile/shared/widgets/mobile_page_head.dart';
import 'package:loadme_mobile/shared/widgets/phone_reveal.dart';
import 'package:loadme_mobile/shared/widgets/swipe_back_wrapper.dart';

// Mirrors web `PostTruckDetail` / `MyPostTruckDetail`. Same layout as load
// detail with truck-specific specs (model, plate, trailer, certificates).
class PostTruckDetailScreen extends ConsumerWidget {
  const PostTruckDetailScreen({
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
    final c = context.colors;
    final s = context.space;
    final t = context.types;

    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: c.background,
        body: Column(
          children: [
            MobilePageHead(
              title: (ownerMode ? 'detail.truck.ownerTitle' : 'detail.truck.title').tr(ref),
              trailing: ownerMode && isActive
                  ? IconButton(
                      onPressed: () => context.push('/edit-post-truck/$id'),
                      icon: Icon(Icons.edit_outlined, size: 22, color: c.primary),
                    )
                  : IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.bookmark_outline_rounded, color: c.textPrimary),
                    ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(s.lg, s.lg, s.lg, s.xl),
                children: [
                  if (!ownerMode) ...[
                    DsCard(
                      child: Row(
                        children: [
                          CircleAvatar(radius: 22, backgroundColor: c.primary50, child: Text('IV', style: t.button.copyWith(color: c.primary))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Ivan Petrov', style: t.bodySemibold),
                                const SizedBox(height: 2),
                                Row(children: [
                                  Icon(Icons.star_rounded, size: 14, color: c.warning300),
                                  const SizedBox(width: 2),
                                  Text('4.8', style: t.caption),
                                ]),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: s.md),
                  ],
                  DsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('detail.section.route'.tr(ref), style: t.h3),
                        SizedBox(height: s.md),
                        _RouteBlock(from: 'Tashkent', to: 'Almaty'),
                      ],
                    ),
                  ),
                  SizedBox(height: s.md),
                  DsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('detail.section.truckInfo'.tr(ref), style: t.h3),
                        SizedBox(height: s.md),
                        _Grid(items: [
                          ('detail.field.model'.tr(ref), 'MAN TGX'),
                          ('detail.field.truckType'.tr(ref), 'Tent / Shtora'),
                          ('detail.field.capacity'.tr(ref), '92 m³'),
                          ('detail.field.weight'.tr(ref), '20 t'),
                          ('detail.field.plate'.tr(ref), '01 A 123 BB'),
                          ('detail.field.trailer'.tr(ref), '01 B 456 CC'),
                        ]),
                      ],
                    ),
                  ),
                  SizedBox(height: s.md),
                  DsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('detail.section.certificatesAndPhotos'.tr(ref), style: t.h3),
                        SizedBox(height: s.md),
                        SizedBox(
                          height: 88,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: 4,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (_, i) => LightboxImage(
                              imageUrl: 'https://picsum.photos/seed/truck-$id-$i/240/240',
                              heroTag: 'truck-$id-$i',
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
                      label: (isActive ? 'detail.archiveTruck' : 'detail.reactivate').tr(ref),
                      variant: isActive ? DsButtonVariant.outline : DsButtonVariant.solid,
                      onPressed: () => _ownerToggle(context, ref),
                    ),
                    SizedBox(height: s.sm),
                    DsButton(
                      label: 'detail.editLoad'.tr(ref),
                      variant: DsButtonVariant.secondary,
                      onPressed: () => context.push('/edit-post-truck/$id'),
                    ),
                  ] else ...[
                    PhoneReveal(
                      phone: '+998901112233',
                      label: 'phone.show'.tr(ref),
                      callLabel: 'phone.call'.tr(ref),
                      onCall: (_) {},
                    ),
                    SizedBox(height: s.sm),
                    Row(
                      children: [
                        Expanded(child: DsButton(label: 'detail.report'.tr(ref), variant: DsButtonVariant.report, icon: Icons.flag_outlined, onPressed: () {})),
                        SizedBox(width: s.sm),
                        Expanded(child: DsButton(label: 'detail.rating'.tr(ref), variant: DsButtonVariant.outline, icon: Icons.star_outline_rounded, onPressed: () {})),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ownerToggle(BuildContext context, WidgetRef ref) async {
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
    final router = GoRouter.of(context);
    try {
      await ref.read(trucksRepositoryProvider).updatePostTruckStatus(guid: id, isActive: !isActive);
      messenger.showSnackBar(SnackBar(content: Text(isActive ? 'Mashina arxivlandi' : 'Mashina qayta faollashtirildi')));
      router.go('/my-trucks');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class _RouteBlock extends StatelessWidget {
  const _RouteBlock({required this.from, required this.to});
  final String from;
  final String to;

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
              const SizedBox(height: 22),
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
