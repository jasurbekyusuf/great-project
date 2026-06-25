import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';
import 'package:loadme_mobile/shared/widgets/select_location_drawer.dart';

// Collapsible filters block shown between the tab switcher and the loads list
// — mirrors the web `LoadsV2` page (origin / destination inputs + Qidiruv/Filtr
// 50:50 buttons).
class LoadsFiltersBlock extends ConsumerStatefulWidget {
  const LoadsFiltersBlock({
    super.key,
    required this.expanded,
    required this.onSearch,
    required this.onFilter,
    this.origin,
    this.destination,
    this.onOriginChanged,
    this.onDestinationChanged,
    this.originPlaceholder,
    this.destPlaceholder,
  });

  final bool expanded;
  final VoidCallback onSearch;
  final VoidCallback onFilter;
  final LocationItem? origin;
  final LocationItem? destination;
  final ValueChanged<LocationItem?>? onOriginChanged;
  final ValueChanged<LocationItem?>? onDestinationChanged;
  final String? originPlaceholder;
  final String? destPlaceholder;

  @override
  ConsumerState<LoadsFiltersBlock> createState() => _LoadsFiltersBlockState();
}

class _LoadsFiltersBlockState extends ConsumerState<LoadsFiltersBlock> {
  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      // Web LoadsV2: padding 10px 16px, gap 8px, filter button fixed 117px.
      child: !widget.expanded
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(
                children: [
                  _LocationInput(
                    icon: Icons.location_on_outlined,
                    value: widget.origin == null
                        ? null
                        : '${widget.origin!.country} · ${widget.origin!.title}',
                    placeholder:
                        widget.originPlaceholder ?? 'loads.originPlace'.tr(ref),
                    onTap: () async {
                      final picked = await showSelectLocationDrawer(
                        context: context,
                        isDestination: false,
                        currentId: widget.origin?.id,
                      );
                      widget.onOriginChanged?.call(picked);
                    },
                  ),
                  const SizedBox(height: 8),
                  _LocationInput(
                    icon: Icons.local_shipping_outlined,
                    value: widget.destination == null
                        ? null
                        : '${widget.destination!.country} · ${widget.destination!.title}',
                    placeholder:
                        widget.destPlaceholder ?? 'loads.destPlace'.tr(ref),
                    onTap: () async {
                      final picked = await showSelectLocationDrawer(
                        context: context,
                        isDestination: true,
                        currentId: widget.destination?.id,
                      );
                      widget.onDestinationChanged?.call(picked);
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        Expanded(
                          child: DsButton(
                            label: 'loads.searchBtn'.tr(ref),
                            icon: Icons.search_rounded,
                            onPressed: widget.onSearch,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Fixed 117px width per web spec.
                        SizedBox(
                          width: 117,
                          child: DsButton(
                            label: 'loads.filterBtn'.tr(ref),
                            icon: Icons.tune_rounded,
                            variant: DsButtonVariant.outline,
                            onPressed: widget.onFilter,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _LocationInput extends StatelessWidget {
  const _LocationInput({
    required this.icon,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  final IconData icon;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.types;
    // Web: h="52px", borderRadius="8px", p="0 18px", gap="8px",
    // icon boxSize 20px / #98A2B3, font 14/400.
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: c.textMuted, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value ?? placeholder,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: value == null
                    ? t.body.copyWith(color: c.textMuted)
                    : t.body.copyWith(color: c.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
