import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_controller.dart';
import 'package:loadme_mobile/features/loads/presentation/widgets/load_figma_card.dart';
import 'package:loadme_mobile/shared/design_system/ds_empty_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_error_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_loader.dart';
import 'package:loadme_mobile/shared/widgets/app_bottom_nav.dart';
import 'package:loadme_mobile/shared/widgets/mobile_auth_required_sheet.dart';
import 'package:loadme_mobile/shared/widgets/mobile_segmented_tab.dart';

// Single Loads list screen used for both guest and authed mode. Pass
// `guest: true` to hide auth-only actions and route to GuestLoad detail.
class LoadsScreen extends ConsumerStatefulWidget {
  const LoadsScreen({super.key, this.guest = false});

  final bool guest;

  @override
  ConsumerState<LoadsScreen> createState() => _LoadsScreenState();
}

class _LoadsScreenState extends ConsumerState<LoadsScreen> {
  int _tabIndex = 0; // 0 = Yuklar, 1 = Yuk mashinalari

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loadsControllerProvider);
    final c = context.colors;
    final s = context.space;

    return Scaffold(
      backgroundColor: c.background,
      bottomNavigationBar: AppBottomNav(currentIndex: 0, guest: widget.guest),
      body: Column(
        children: [
          _LoadsHeader(
            tabIndex: _tabIndex,
            tabLabels: ['loads.title'.tr(ref), 'trucks.title'.tr(ref)],
            onTabChanged: (i) {
              setState(() => _tabIndex = i);
              if (i == 1) context.go(widget.guest ? '/guest-trucks' : '/trucks');
            },
          ),
          Expanded(
            child: Column(
              children: [
                _FilterRow(guest: widget.guest),
                Expanded(
                  child: state.when(
                    loading: () => const DsLoader(),
                    error: (e, _) => DsErrorState(
                      message: e.toString(),
                      onRetry: () => ref.read(loadsControllerProvider.notifier).refresh(),
                    ),
                    data: (items) {
                      if (items.isEmpty) return DsEmptyState(title: 'common.notFound'.tr(ref));
                      return RefreshIndicator(
                        onRefresh: () => ref.read(loadsControllerProvider.notifier).refresh(),
                        child: ListView.separated(
                          padding: EdgeInsets.fromLTRB(s.lg, 0, s.lg, s.lg),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => SizedBox(height: s.sm),
                          itemBuilder: (_, i) {
                            final item = items[i];
                            return LoadFigmaCard(
                              load: item,
                              distanceKm: 600 + i * 100,
                              roleBadge: 'Admin',
                              truckType: i.isEven ? 'Tent / Shtora' : 'Isuzu NQR / NPR',
                              loadKind: "To'liq",
                              priceLabel: 'common.negotiable'.tr(ref),
                              onTap: () {
                                if (widget.guest) {
                                  context.push('/guest-load/${item.guid}');
                                } else {
                                  context.push('/loads/${item.guid}');
                                }
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadsHeader extends StatelessWidget {
  const _LoadsHeader({required this.tabIndex, required this.tabLabels, required this.onTabChanged});

  final int tabIndex;
  final List<String> tabLabels;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.space;
    final t = context.types;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(s.radiusXl),
          bottomRight: Radius.circular(s.radiusXl),
        ),
        border: Border(bottom: BorderSide(color: c.borderSubtle)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: c.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: const Text('L', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                  Text('LoadMe', style: t.h3),
                ],
              ),
              const SizedBox(height: 12),
              MobileSegmentedTab(
                items: tabLabels,
                selectedIndex: tabIndex,
                onChanged: onTabChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends ConsumerWidget {
  const _FilterRow({required this.guest});
  final bool guest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.types;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              if (guest) {
                showMobileAuthRequiredSheet(context);
              } else {
                context.push('/loads/filters');
              }
            },
            child: Row(children: [
              Icon(Icons.tune_rounded, size: 18, color: c.primary),
              const SizedBox(width: 6),
              Text('${'loads.allCount'.tr(ref)}: 15840', style: t.bodyMedium.copyWith(color: c.primary, fontWeight: FontWeight.w600)),
            ]),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('common.show'.tr(ref), style: t.caption.copyWith(color: c.textPrimary)),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: c.textPrimary),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.refresh_rounded, size: 20, color: c.textSecondary),
        ],
      ),
    );
  }
}
