import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_controller.dart';
import 'package:loadme_mobile/shared/design_system/ds_action_drawer.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';
import 'package:loadme_mobile/shared/widgets/mobile_page_head.dart';
import 'package:loadme_mobile/shared/widgets/select_location_drawer.dart';
import 'package:loadme_mobile/shared/widgets/swipe_back_wrapper.dart';

// Mirrors web `LoadsFilters` screen (src/modules/LoadsFilters).
// Fields: from, to, truck type, load type, weight, volume, dead-head, date,
// rating, payment type. Apply + reset bottom bar.
class LoadsFiltersScreen extends ConsumerStatefulWidget {
  const LoadsFiltersScreen({super.key});

  @override
  ConsumerState<LoadsFiltersScreen> createState() => _LoadsFiltersScreenState();
}

class _LoadsFiltersScreenState extends ConsumerState<LoadsFiltersScreen> {
  final _query = TextEditingController();
  final _weight = TextEditingController();
  final _volume = TextEditingController();
  final _deadHead = TextEditingController();

  LocationItem? _from;
  LocationItem? _to;
  String? _truckType;
  String? _loadKind;
  String? _payment;
  DateTimeRange? _pickupRange;
  double _minRating = 0;

  static const _truckTypes = [
    'Tent / Shtora', 'Refrigerator', 'Isuzu NQR / NPR', 'Trailer', 'Container 20\'', 'Container 40\'',
  ];
  static const _loadKinds = ["To'liq", 'Yarim', 'Konteyner', 'Maxsus'];
  static const _payments = ['Naqd', 'Pul ko\'chirma', 'Kelishiladi'];

  @override
  void dispose() {
    _query.dispose();
    _weight.dispose();
    _volume.dispose();
    _deadHead.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.space;

    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: c.background,
        body: Column(
          children: [
            MobilePageHead(
              title: 'filters.title'.tr(ref),
              trailing: TextButton(
                onPressed: _reset,
                child: Text('filters.reset'.tr(ref), style: TextStyle(color: c.error)),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(s.lg),
                children: [
                  _Field(
                    label: 'filters.search'.tr(ref),
                    placeholder: 'filters.searchHint'.tr(ref),
                    controller: _query,
                    icon: Icons.search_rounded,
                  ),
                  SizedBox(height: s.md),
                  _SelectTile(
                    label: 'filters.from'.tr(ref),
                    value: _from == null ? null : '${_from!.country} · ${_from!.title}',
                    placeholder: 'form.label.choose'.tr(ref),
                    icon: Icons.trip_origin_rounded,
                    onTap: () async {
                      final v = await showSelectLocationDrawer(context: context, title: 'filters.from'.tr(ref), currentId: _from?.id);
                      if (v != null) setState(() => _from = v);
                    },
                  ),
                  SizedBox(height: s.md),
                  _SelectTile(
                    label: 'filters.to'.tr(ref),
                    value: _to == null ? null : '${_to!.country} · ${_to!.title}',
                    placeholder: 'form.label.choose'.tr(ref),
                    icon: Icons.place_rounded,
                    onTap: () async {
                      final v = await showSelectLocationDrawer(context: context, title: 'filters.to'.tr(ref), currentId: _to?.id);
                      if (v != null) setState(() => _to = v);
                    },
                  ),
                  SizedBox(height: s.md),
                  _SelectTile(
                    label: 'filters.truckType'.tr(ref),
                    value: _truckType,
                    placeholder: 'form.label.choose'.tr(ref),
                    onTap: () async {
                      final v = await showDsActionDrawer<String>(
                        context: context,
                        title: 'filters.truckType'.tr(ref),
                        currentValue: _truckType,
                        items: _truckTypes.map((t) => DsActionDrawerItem(value: t, label: t)).toList(),
                      );
                      if (v != null) setState(() => _truckType = v);
                    },
                  ),
                  SizedBox(height: s.md),
                  _SelectTile(
                    label: 'filters.loadType'.tr(ref),
                    value: _loadKind,
                    placeholder: 'form.label.choose'.tr(ref),
                    onTap: () async {
                      final v = await showDsActionDrawer<String>(
                        context: context,
                        title: 'filters.loadType'.tr(ref),
                        currentValue: _loadKind,
                        items: _loadKinds.map((t) => DsActionDrawerItem(value: t, label: t)).toList(),
                      );
                      if (v != null) setState(() => _loadKind = v);
                    },
                  ),
                  SizedBox(height: s.md),
                  Row(
                    children: [
                      Expanded(child: _Field(label: 'filters.weight'.tr(ref), placeholder: '0', controller: _weight, suffix: 't', keyboardType: TextInputType.number)),
                      SizedBox(width: s.md),
                      Expanded(child: _Field(label: 'filters.volume'.tr(ref), placeholder: '0', controller: _volume, suffix: 'm³', keyboardType: TextInputType.number)),
                    ],
                  ),
                  SizedBox(height: s.md),
                  _Field(label: 'filters.deadHead'.tr(ref), placeholder: '0', controller: _deadHead, suffix: 'km', keyboardType: TextInputType.number),
                  SizedBox(height: s.md),
                  _SelectTile(
                    label: 'filters.pickupDate'.tr(ref),
                    value: _pickupRange == null
                        ? null
                        : '${_fmt(_pickupRange!.start)} → ${_fmt(_pickupRange!.end)}',
                    placeholder: 'form.label.choose'.tr(ref),
                    icon: Icons.calendar_today_rounded,
                    onTap: _pickDateRange,
                  ),
                  SizedBox(height: s.md),
                  _SelectTile(
                    label: 'filters.payment'.tr(ref),
                    value: _payment,
                    placeholder: 'form.label.choose'.tr(ref),
                    icon: Icons.payments_outlined,
                    onTap: () async {
                      final v = await showDsActionDrawer<String>(
                        context: context,
                        title: 'filters.payment'.tr(ref),
                        currentValue: _payment,
                        items: _payments.map((t) => DsActionDrawerItem(value: t, label: t)).toList(),
                      );
                      if (v != null) setState(() => _payment = v);
                    },
                  ),
                  SizedBox(height: s.lg),
                  _RatingSlider(
                    label: 'filters.minRating'.tr(ref),
                    value: _minRating,
                    onChanged: (v) => setState(() => _minRating = v),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(s.lg, s.sm, s.lg, s.md),
                child: Row(
                  children: [
                    Expanded(child: DsButton(label: 'filters.reset'.tr(ref), variant: DsButtonVariant.outline, onPressed: _reset)),
                    SizedBox(width: s.md),
                    Expanded(child: DsButton(label: 'filters.apply'.tr(ref), onPressed: _apply)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _pickupRange,
    );
    if (picked != null) setState(() => _pickupRange = picked);
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  void _reset() {
    setState(() {
      _query.clear();
      _weight.clear();
      _volume.clear();
      _deadHead.clear();
      _from = null;
      _to = null;
      _truckType = null;
      _loadKind = null;
      _payment = null;
      _pickupRange = null;
      _minRating = 0;
    });
  }

  void _apply() {
    final query = [
      _query.text.trim(),
      _from?.title ?? '',
      _to?.title ?? '',
    ].where((e) => e.isNotEmpty).join(' ');
    ref.read(loadsControllerProvider.notifier).applyQuery(query);
    context.go('/loads');
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.placeholder,
    required this.controller,
    this.suffix,
    this.icon,
    this.keyboardType,
  });

  final String label;
  final String placeholder;
  final TextEditingController controller;
  final String? suffix;
  final IconData? icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.types;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: t.caption.copyWith(color: c.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: placeholder,
            suffixText: suffix,
            prefixIcon: icon == null ? null : Icon(icon, color: c.textMuted, size: 18),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

class _SelectTile extends StatelessWidget {
  const _SelectTile({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.icon,
  });

  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.types;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: t.caption.copyWith(color: c.textSecondary)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                if (icon != null) ...[Icon(icon, color: c.textMuted, size: 18), const SizedBox(width: 8)],
                Expanded(
                  child: Text(
                    value ?? placeholder,
                    style: t.body.copyWith(color: value == null ? c.textMuted : c.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, color: c.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RatingSlider extends StatelessWidget {
  const _RatingSlider({required this.label, required this.value, required this.onChanged});
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.types;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: t.caption.copyWith(color: c.textSecondary))),
            Text(value.toStringAsFixed(1), style: t.bodySemibold),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 5,
          divisions: 10,
          activeColor: c.primary,
          inactiveColor: c.border,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
