import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/loads/domain/entities/load_entity.dart';

// Mirrors the Loads list card design from Figma (Load_me_Udevs):
// - Header row: owner name + rating star + agreed/price link (right)
// - Body: from/to route with dotted connector and country pills (UZ/KG)
// - Right: pickup date
// - Footer: role + truck type + capacity + distance chips
class LoadFigmaCard extends StatelessWidget {
  const LoadFigmaCard({
    super.key,
    required this.load,
    required this.onTap,
    this.ownerName = 'LoadMe admin',
    this.ownerRating = 5.0,
    this.priceLabel,
    this.fromCountry = 'UZ',
    this.toCountry = 'UZ',
    this.roleBadge,
    this.truckType = 'Tent / Shtora',
    this.loadKind = "To'liq",
    this.distanceKm,
  });

  final LoadEntity load;
  final VoidCallback onTap;
  final String ownerName;
  final double ownerRating;
  final String? priceLabel;
  final String fromCountry;
  final String toCountry;
  final String? roleBadge;
  final String truckType;
  final String loadKind;
  final int? distanceKm;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.space;
    final t = context.types;

    final dateText = _formatDate(load.pickupDate);

    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(s.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(s.radiusLg),
        child: Container(
          padding: EdgeInsets.all(s.md),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(s.radiusLg),
            border: Border.all(color: c.borderSubtle, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: owner + rating | price link
              Row(
                children: [
                  Flexible(
                    child: Text(
                      ownerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySemibold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(ownerRating.toStringAsFixed(1), style: t.caption.copyWith(color: c.textSecondary)),
                  const SizedBox(width: 2),
                  Icon(Icons.star_rounded, size: 14, color: c.warning300),
                  const Spacer(),
                  if (priceLabel != null)
                    Text(priceLabel!, style: t.bodyMedium.copyWith(color: c.primary)),
                ],
              ),
              SizedBox(height: s.md),

              // Route block + date
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dotted connector column
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
                        ),
                        const SizedBox(height: 2),
                        _DottedVerticalLine(color: c.gray300, height: 22),
                        const SizedBox(height: 2),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: c.primary, width: 1.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RouteRow(country: fromCountry, address: load.fromAddress),
                        const SizedBox(height: 12),
                        _RouteRow(country: toCountry, address: load.toAddress),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (dateText != null)
                    Text(dateText, style: t.caption.copyWith(color: c.textMuted)),
                ],
              ),

              SizedBox(height: s.md),

              // Chip row — theme-aware colors (surfaceMuted adapts to dark mode).
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (roleBadge != null)
                    _Chip(text: roleBadge!, color: c.yellow100, textColor: c.yellow700),
                  _Chip(text: truckType, color: c.surfaceMuted, textColor: c.textPrimary, border: c.borderSubtle),
                  if (distanceKm != null)
                    _Chip(text: '$distanceKm km', color: c.surfaceMuted, textColor: c.textPrimary, border: c.borderSubtle),
                  _Chip(text: loadKind, color: c.surfaceMuted, textColor: c.textPrimary, border: c.borderSubtle),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _wdays = ['Du', 'Se', 'Cho', 'Pa', 'Ju', 'Sha', 'Yak'];

  String? _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final d = DateTime.tryParse(raw);
    if (d == null) return raw;
    final wd = _wdays[(d.weekday - 1).clamp(0, 6)];
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$wd $dd/$mm';
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({required this.country, required this.address});
  final String country;
  final String address;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.types;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: c.primary50,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            country,
            style: t.caption.copyWith(color: c.primary, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color, required this.textColor, this.border});
  final String text;
  final Color color;
  final Color textColor;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final t = context.types;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: border == null ? null : Border.all(color: border!, width: 1),
      ),
      child: Text(text, style: t.caption.copyWith(color: textColor)),
    );
  }
}

class _DottedVerticalLine extends StatelessWidget {
  const _DottedVerticalLine({required this.color, required this.height});
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1.5,
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const dot = 2.0;
          const gap = 3.0;
          final count = (constraints.maxHeight / (dot + gap)).floor();
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(count, (_) => SizedBox(
              width: 1.5,
              height: dot,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            )),
          );
        },
      ),
    );
  }
}
