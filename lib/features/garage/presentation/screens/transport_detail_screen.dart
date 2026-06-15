import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/features/garage/presentation/providers/garage_providers.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';
import 'package:loadme_mobile/shared/design_system/ds_error_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_loader.dart';
import 'package:loadme_mobile/shared/widgets/app_svg_icon.dart';
import 'package:loadme_mobile/shared/widgets/frosted_header.dart';
import 'package:loadme_mobile/shared/widgets/load_card_parts.dart';
import 'package:loadme_mobile/shared/widgets/swipe_back_wrapper.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Figma "Transport ma'lumotlari" (node 6473-32675): full-screen detail shown
/// when a vehicle in the Garaj → Transportlar tab is tapped. Vehicle + route +
/// price, a spec list, and the carrier contact block with a sticky CTA.
class TransportDetailScreen extends ConsumerWidget {
  const TransportDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(transportDetailProvider(id));

    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: FigmaPalette.sheetBg,
        body: Column(
          children: [
            FrostedHeader(
              title: 'transport.detail.title'.tr(ref),
              trailing: const Icon(LucideIcons.bookmark,
                  size: 22, color: FigmaPalette.ink),
            ),
            Expanded(
              child: detail.when(
                loading: () => const DsLoader(),
                error: (e, _) => DsErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(transportDetailProvider(id)),
                ),
                data: (d) => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  children: [
                    _SummaryCard(detail: d),
                    const SizedBox(height: 12),
                    _SpecsCard(detail: d),
                    const SizedBox(height: 12),
                    _ContactCard(detail: d),
                  ],
                ),
              ),
            ),
            // The contact CTA only makes sense once the carrier data is loaded.
            if (detail.hasValue)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: DsButton(
                    label: 'transport.contact'.tr(ref),
                    onPressed: () {},
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
// Summary card — vehicle, route (with dates) and price
// ---------------------------------------------------------------------------
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.detail});
  final TransportDetail detail;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle row.
          Row(
            children: [
              const TruckAvatar(size: 48),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VehicleTypeChip(label: detail.vehicleName),
                    const SizedBox(height: 4),
                    Text(
                      detail.vehicleModel,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 18 / 12,
                        fontWeight: FontWeight.w500,
                        color: FigmaPalette.label,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: FigmaPalette.divider),
          const SizedBox(height: 12),
          // Route with dates.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 2),
                  appSvgIcon('card_cube', size: 14, color: FigmaPalette.inkStrong),
                  const DottedConnector(height: 22, width: 14, color: FigmaPalette.label),
                  appSvgIcon('card_flag', size: 14, color: FigmaPalette.inkStrong),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RoutePoint(
                      city: detail.fromCity,
                      subtitle: detail.fromSubtitle,
                      date: detail.fromDate,
                    ),
                    const SizedBox(height: 12),
                    _RoutePoint(
                      city: detail.toCity,
                      subtitle: detail.toSubtitle,
                      date: detail.toDate,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Payment box.
          DecoratedBox(
            decoration: BoxDecoration(
              color: FigmaPalette.chipBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: FigmaPalette.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(LucideIcons.banknote, size: 20, color: FigmaPalette.primary),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        detail.paymentLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 18 / 12,
                          fontWeight: FontWeight.w500,
                          color: FigmaPalette.gray700,
                        ),
                      ),
                      Text(
                        detail.priceLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w600,
                          color: FigmaPalette.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({required this.city, required this.subtitle, required this.date});
  final String city;
  final String subtitle;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
            const SizedBox(width: 8),
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
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            height: 15 / 12,
            fontWeight: FontWeight.w500,
            color: FigmaPalette.label,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Specs card
// ---------------------------------------------------------------------------
class _SpecsCard extends ConsumerWidget {
  const _SpecsCard({required this.detail});
  final TransportDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = <(IconData, String, String)>[
      (LucideIcons.truck, 'transport.field.number'.tr(ref), detail.plate),
      (LucideIcons.package, 'transport.field.loadType'.tr(ref), detail.loadType),
      (LucideIcons.locateFixed, 'transport.field.radius'.tr(ref), detail.radius),
      (LucideIcons.route, 'detail.field.distance'.tr(ref), detail.distance),
      (LucideIcons.weight, 'detail.field.weight'.tr(ref), detail.weight),
      (LucideIcons.scan, 'transport.field.capacity'.tr(ref), detail.capacity),
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1, color: FigmaPalette.divider),
            _SpecRow(icon: rows[i].$1, label: rows[i].$2, value: rows[i].$3),
          ],
          const Divider(height: 1, thickness: 1, color: FigmaPalette.divider),
          const SizedBox(height: 10),
          Text(
            '${'detail.section.comment'.tr(ref)}:',
            style: const TextStyle(
              fontSize: 12,
              height: 18 / 12,
              fontWeight: FontWeight.w500,
              color: FigmaPalette.label,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail.comment,
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
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 18, color: FigmaPalette.primary),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 12,
              height: 18 / 12,
              fontWeight: FontWeight.w500,
              color: FigmaPalette.gray700,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
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
// Contact card
// ---------------------------------------------------------------------------
class _ContactCard extends ConsumerWidget {
  const _ContactCard({required this.detail});
  final TransportDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TruckAvatar(size: 48),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      detail.contactName,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 18 / 14,
                        fontWeight: FontWeight.w500,
                        color: FigmaPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          detail.contactRating.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            height: 18 / 12,
                            fontWeight: FontWeight.w500,
                            color: FigmaPalette.label,
                          ),
                        ),
                        const SizedBox(width: 2),
                        appSvgIcon('card_star', size: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: FigmaPalette.divider),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _ContactLink(label: 'Telegram:', value: detail.telegram)),
              const SizedBox(width: 12),
              Expanded(child: _ContactLink(label: 'Whatsapp:', value: detail.whatsapp)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ChipButton(
                  icon: LucideIcons.star,
                  label: 'transport.rate'.tr(ref),
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ChipButton(
                  icon: LucideIcons.flag,
                  label: 'transport.report'.tr(ref),
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactLink extends StatelessWidget {
  const _ContactLink({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
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
            color: FigmaPalette.label,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            height: 18 / 12,
            fontWeight: FontWeight.w500,
            color: FigmaPalette.primary,
          ),
        ),
      ],
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FigmaPalette.chipBg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: FigmaPalette.ink),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  height: 18 / 12,
                  fontWeight: FontWeight.w500,
                  color: FigmaPalette.ink,
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
// Shared bits
// ---------------------------------------------------------------------------
class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: FigmaPalette.cardShadow, offset: Offset(0, 2), blurRadius: 8),
        ],
      ),
      child: child,
    );
  }
}
