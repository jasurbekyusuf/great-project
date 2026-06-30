import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/garage/presentation/providers/garage_providers.dart';
import 'package:loadme_mobile/features/magnit/presentation/providers/magnit_providers.dart';
import 'package:loadme_mobile/shared/design_system/ds_action_drawer.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';
import 'package:loadme_mobile/shared/design_system/ds_success_modal.dart';
import 'package:loadme_mobile/shared/widgets/frosted_header.dart';
import 'package:loadme_mobile/shared/widgets/select_location_drawer.dart';
import 'package:loadme_mobile/shared/widgets/swipe_back_wrapper.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Mirrors the Figma "Magnit" screen 1:1. Opened from the center magnet button
// in the bottom navigation. It's a load-matching alert form: activating it
// creates an auto truck-route (`POST /trucks/routes/magnet/`) so that when a
// load matching the chosen pickup + truck type appears, the carrier is notified.
class MagnitScreen extends ConsumerStatefulWidget {
  const MagnitScreen({super.key});

  @override
  ConsumerState<MagnitScreen> createState() => _MagnitScreenState();
}

class _MagnitScreenState extends ConsumerState<MagnitScreen> {
  final _price = TextEditingController();
  final _comment = TextEditingController();
  final _maxWeight = TextEditingController();

  // Anchors the Radius dropdown menu under the radius field.
  final _radiusFieldKey = GlobalKey();

  LocationItem? _from;
  LocationItem? _to;
  String? _radius;
  MagnitTruckType? _transport;
  String? _cargoType;
  String? _period;
  // Magnit opens collapsed: only the 3 core fields (Qaerdan / Qaerga /
  // Transport) show, with a "Ko'proq" toggle to reveal the optional fields.
  bool _expanded = false;
  bool _submitting = false;

  @override
  void dispose() {
    _price.dispose();
    _comment.dispose();
    _maxWeight.dispose();
    super.dispose();
  }

  String? _loc(LocationItem? l) => l?.displayLabel;

  Future<void> _pickLocation({required bool isFrom}) async {
    final v = await showSelectLocationDrawer(
      context: context,
      isDestination: !isFrom,
      // Destination is optional here, so "Har qanday joyga" is a real choice
      // (anywhere sentinel) the user can pick; pickup stays mandatory.
      allowAnywhere: !isFrom,
      currentId: (isFrom ? _from : _to)?.id,
    );
    if (v != null) setState(() => isFrom ? _from = v : _to = v);
  }

  // Figma uses a dropdown anchored to the field (not a bottom sheet) with a
  // checkmark on the selected radius. Values: 50 / 100 / 150 / 200 / 300 km.
  Future<void> _pickRadius() async {
    final anchorCtx = _radiusFieldKey.currentContext;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (anchorCtx == null || overlay == null) return;
    final box = anchorCtx.findRenderObject()! as RenderBox;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final position = RelativeRect.fromLTRB(
      topLeft.dx,
      topLeft.dy + box.size.height + 4,
      overlay.size.width - (topLeft.dx + box.size.width),
      0,
    );
    const values = ['50', '100', '150', '200', '300'];
    final v = await showMenu<String>(
      context: context,
      position: position,
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 220),
      items: [
        for (final val in values)
          PopupMenuItem<String>(
            value: val,
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _RadiusMenuRow(label: '$val km', selected: _radius == val),
          ),
      ],
    );
    if (v != null) setState(() => _radius = v);
  }

  // The magnet endpoint needs a `truck_type` UUID, so the picker is driven by
  // the real `/trucks/types/` directory rather than the local label taxonomy.
  Future<void> _pickTransport() async {
    final List<MagnitTruckType> types;
    try {
      // Drop any cached error/empty result so each tap retries a fresh fetch.
      ref.invalidate(truckTypesProvider);
      types = await ref.read(truckTypesProvider.future);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('magnit.typesError'.tr(ref))),
      );
      return;
    }
    if (!mounted) return;
    // An empty directory must not look like a dead tap — tell the user.
    if (types.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('magnit.typesError'.tr(ref))),
      );
      return;
    }
    final v = await showDsActionDrawer<String>(
      context: context,
      title: 'magnit.transport'.tr(ref),
      currentValue: _transport?.id,
      items: [
        for (final t in types) DsActionDrawerItem(value: t.id, label: t.name),
      ],
    );
    if (v == null) return;
    setState(() => _transport = types.firstWhere((t) => t.id == v));
  }

  Future<void> _pickCargoType() async {
    final v = await showDsActionDrawer<String>(
      context: context,
      title: 'magnit.cargoType'.tr(ref),
      currentValue: _cargoType,
      items: [
        DsActionDrawerItem(value: 'full', label: 'magnit.cargo.full'.tr(ref)),
        DsActionDrawerItem(value: 'partial', label: 'magnit.cargo.partial'.tr(ref)),
      ],
    );
    if (v != null) setState(() => _cargoType = v);
  }

  Future<void> _pickPeriod() async {
    final v = await showDsActionDrawer<String>(
      context: context,
      title: 'magnit.period'.tr(ref),
      currentValue: _period,
      items: [
        DsActionDrawerItem(value: '1d', label: 'magnit.period.1d'.tr(ref)),
        DsActionDrawerItem(value: '3d', label: 'magnit.period.3d'.tr(ref)),
        DsActionDrawerItem(value: '1w', label: 'magnit.period.1w'.tr(ref)),
        DsActionDrawerItem(value: '10d', label: 'magnit.period.10d'.tr(ref)),
      ],
    );
    if (v != null) setState(() => _period = v);
  }

  Future<void> _editText({
    required String title,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => _TextInputSheet(
        title: title,
        initial: controller.text,
        keyboardType: keyboardType,
        confirmLabel: 'common.confirm'.tr(ref),
      ),
    );
    if (result != null) setState(() => controller.text = result);
  }

  // Sends `pickup_<filterKey>` (+ optional delivery / radius) and the chosen
  // `truck_type` UUID to `POST /trucks/routes/magnet/`. Pickup and transport are
  // mandatory; a `truck_required` reply means the carrier must first add a truck
  // of that type.
  Future<void> _submit() async {
    final from = _from;
    final type = _transport;
    if (from == null || type == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('magnit.requiredFields'.tr(ref))),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final to = _to;
      // The magnet creates a truck route, which requires the FULL pickup chain
      // (`pickup_country` + `pickup_region` are mandatory, per the route
      // contract). Sending only the picked level (e.g. just `pickup_region`)
      // 400s — so emit the whole country→region→district chain via the
      // LocationItem parent ids.
      final result = await ref.read(magnitRepositoryProvider).activate(
            truckType: type.id,
            pickupCountry: from.countryFilterId,
            pickupRegion: from.regionFilterId,
            pickupDistrict: from.districtFilterId,
            deliveryCountry: to?.countryFilterId,
            deliveryRegion: to?.regionFilterId,
            deliveryDistrict: to?.districtFilterId,
            deadheadRadiusKm: _radius == null ? null : int.tryParse(_radius!),
          );
      if (!mounted) return;
      final activation = result.fold<MagnitActivation?>(
        (f) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(f.message)),
          );
          return null;
        },
        (a) => a,
      );
      if (activation == null) return;
      if (activation.status == MagnitStatus.truckRequired) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('magnit.truckRequired'.tr(ref))),
        );
        return;
      }
      // A magnet publishes an auto-route on Garaj → Yo'nalishlarim.
      ref.invalidate(garageRoutesProvider);
      await showDsSuccessModal(
        context,
        title: 'magnit.success.title'.tr(ref),
        message: 'magnit.success.message'.tr(ref),
        actionLabel: 'common.confirm'.tr(ref),
        onAction: () => context.canPop() ? context.pop() : context.go('/garage'),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: FigmaPalette.sheetBg,
        body: Column(
          children: [
            FrostedHeader(title: 'magnit.title'.tr(ref)),
            Expanded(
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                children: [
                  _InfoBanner(text: 'magnit.banner'.tr(ref)),
                  const SizedBox(height: 8),
                  _RouteCard(
                    radiusKey: _radiusFieldKey,
                    fromValue: _loc(_from),
                    toValue: _loc(_to),
                    radiusValue: _radius == null ? null : '$_radius km',
                    fromLabel: 'magnit.from'.tr(ref),
                    toLabel: 'magnit.to'.tr(ref),
                    radiusLabel: 'magnit.radius'.tr(ref),
                    fromHint: 'magnit.fromHint'.tr(ref),
                    toHint: 'magnit.toHint'.tr(ref),
                    chooseHint: 'magnit.choose'.tr(ref),
                    onFrom: () => _pickLocation(isFrom: true),
                    onTo: () => _pickLocation(isFrom: false),
                    onRadius: _pickRadius,
                  ),
                  const SizedBox(height: 8),
                  _MagnitField(
                    icon: Icons.local_shipping_outlined,
                    label: 'magnit.transport'.tr(ref),
                    value: _transport?.name,
                    placeholder: 'magnit.transportHint'.tr(ref),
                    isRequired: true,
                    onTap: _pickTransport,
                  ),
                  const SizedBox(height: 16),
                  _CollapseToggle(
                    label: (_expanded ? 'magnit.collapse' : 'magnit.expand').tr(ref),
                    expanded: _expanded,
                    onTap: () => setState(() => _expanded = !_expanded),
                  ),
                  if (_expanded) ...[
                    const SizedBox(height: 8),
                    _MagnitField(
                      icon: Icons.crop_free_rounded,
                      label: 'magnit.cargoType'.tr(ref),
                      value: _cargoType == null
                          ? null
                          : 'magnit.cargo.${_cargoType!}'.tr(ref),
                      placeholder: 'magnit.choose'.tr(ref),
                      onTap: _pickCargoType,
                    ),
                    const SizedBox(height: 8),
                    _MagnitField(
                      icon: Icons.pending_actions_outlined,
                      label: 'magnit.period'.tr(ref),
                      value: _period == null ? null : 'magnit.period.${_period!}'.tr(ref),
                      placeholder: 'magnit.periodHint'.tr(ref),
                      onTap: _pickPeriod,
                    ),
                    const SizedBox(height: 8),
                    _MagnitField(
                      icon: Icons.monetization_on_outlined,
                      label: 'magnit.price'.tr(ref),
                      value: _price.text.isEmpty ? null : _price.text,
                      placeholder: 'magnit.priceHint'.tr(ref),
                      onTap: () => _editText(
                        title: 'magnit.price'.tr(ref),
                        controller: _price,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _MagnitField(
                      icon: LucideIcons.weight,
                      label: 'magnit.weightVolume'.tr(ref),
                      value: _maxWeight.text.isEmpty ? null : _maxWeight.text,
                      placeholder: 'magnit.weightVolumeHint'.tr(ref),
                      onTap: () => _editText(
                        title: 'magnit.weightVolume'.tr(ref),
                        controller: _maxWeight,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _MagnitField(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'magnit.comment'.tr(ref),
                      value: _comment.text.isEmpty ? null : _comment.text,
                      placeholder: 'magnit.commentHint'.tr(ref),
                      onTap: () => _editText(
                        title: 'magnit.comment'.tr(ref),
                        controller: _comment,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _SubmitButton(
                  label: 'magnit.submit'.tr(ref),
                  loading: _submitting,
                  onPressed: _submitting ? null : _submit,
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
// Info banner — light-blue gradient, magnet badge + helper text.
// ---------------------------------------------------------------------------
class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.types;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDBE6FC), Color(0xFFF2F6FE)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.primary.withValues(alpha: 0.24), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset('assets/images/magnit_badge.png', width: 36, height: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: t.body.copyWith(fontSize: 13, height: 20 / 13, color: c.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Route card — origin + radius (top), destination (bottom), with a dotted
// connector on the left and a hairline divider between the rows.
// ---------------------------------------------------------------------------
class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.radiusKey,
    required this.fromValue,
    required this.toValue,
    required this.radiusValue,
    required this.fromLabel,
    required this.toLabel,
    required this.radiusLabel,
    required this.fromHint,
    required this.toHint,
    required this.chooseHint,
    required this.onFrom,
    required this.onTo,
    required this.onRadius,
  });

  final Key radiusKey;
  final String? fromValue;
  final String? toValue;
  final String? radiusValue;
  final String fromLabel;
  final String toLabel;
  final String radiusLabel;
  final String fromHint;
  final String toHint;
  final String chooseHint;
  final VoidCallback onFrom;
  final VoidCallback onTo;
  final VoidCallback onRadius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Top row: origin | divider | radius
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _FieldInner(
                    icon: Icons.view_in_ar_outlined,
                    chipSize: 36,
                    chipRadius: 12,
                    label: fromLabel,
                    value: fromValue,
                    placeholder: fromHint,
                    isRequired: true,
                    onTap: onFrom,
                  ),
                ),
                const SizedBox(width: 14),
                Container(width: 1, color: c.border),
                const SizedBox(width: 14),
                SizedBox(
                  key: radiusKey,
                  width: 86,
                  child: _FieldInner(
                    label: radiusLabel,
                    value: radiusValue,
                    placeholder: chooseHint,
                    onTap: onRadius,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          // Connector (dashed) + hairline divider
          SizedBox(
            height: 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 36, child: Center(child: _DottedLine(height: 18, color: c.gray400))),
                const SizedBox(width: 8),
                Expanded(child: Container(height: 1, color: const Color(0xFFD5D9E1))),
              ],
            ),
          ),
          const SizedBox(height: 2),
          // Destination row (full width)
          _FieldInner(
            icon: Icons.flag_outlined,
            chipSize: 36,
            chipRadius: 12,
            label: toLabel,
            value: toValue,
            placeholder: toHint,
            onTap: onTo,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Standalone field card (Transport, To'liq/Dagruz, Narxi, …).
// ---------------------------------------------------------------------------
class _MagnitField extends StatelessWidget {
  const _MagnitField({
    required this.icon,
    required this.label,
    required this.placeholder,
    required this.onTap,
    this.value,
    this.isRequired = false,
  });

  final IconData icon;
  final String label;
  final String placeholder;
  final VoidCallback onTap;
  final String? value;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _FieldInner(
            icon: icon,
            label: label,
            value: value,
            placeholder: placeholder,
            isRequired: isRequired,
            onTap: null,
          ),
        ),
      ),
    );
  }
}

// Shared inner layout: [icon chip] label / value-or-placeholder [chevron].
class _FieldInner extends StatelessWidget {
  const _FieldInner({
    required this.label,
    required this.placeholder,
    required this.onTap,
    this.icon,
    this.value,
    this.chipSize = 32,
    this.chipRadius = 10,
    this.isRequired = false,
  });

  final IconData? icon;
  final String label;
  final String placeholder;
  final String? value;
  final double chipSize;
  final double chipRadius;
  final VoidCallback? onTap;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.types;

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Container(
            width: chipSize,
            height: chipSize,
            decoration: BoxDecoration(
              color: const Color(0xFFEBEBEB),
              borderRadius: BorderRadius.circular(chipRadius),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: c.primary),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: t.caption.copyWith(
                      fontWeight: FontWeight.w400,
                      height: 14.5 / 12,
                      color: const Color(0xFF0B1020),
                    ),
                  ),
                  if (isRequired) ...[
                    const SizedBox(width: 2),
                    Text(
                      '*',
                      style: t.caption.copyWith(
                        fontWeight: FontWeight.w400,
                        height: 14.5 / 12,
                        color: const Color(0xFFB42318),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                value ?? placeholder,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodyLg.copyWith(color: value == null ? c.textMuted : c.textPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(LucideIcons.chevronRight, size: 16, color: c.textPrimary),
      ],
    );

    if (onTap == null) return row;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: row);
  }
}

// ---------------------------------------------------------------------------
// Collapse toggle ("Yopish" / "Ochish").
// ---------------------------------------------------------------------------
class _CollapseToggle extends StatelessWidget {
  const _CollapseToggle({required this.label, required this.expanded, required this.onTap});
  final String label;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.types;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: t.bodyMedium.copyWith(fontWeight: FontWeight.w400, color: c.primary)),
                const SizedBox(width: 6),
                Icon(
                  expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 20,
                  color: c.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DottedLine extends StatelessWidget {
  const _DottedLine({required this.height, required this.color});
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1.5,
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const dot = 3.0;
          const gap = 3.0;
          final count = (constraints.maxHeight / (dot + gap)).floor().clamp(1, 99);
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              count,
              (_) => SizedBox(
                width: 1.5,
                height: dot,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// One row of the Radius dropdown menu — label + a blue check on the selected.
// ---------------------------------------------------------------------------
class _RadiusMenuRow extends StatelessWidget {
  const _RadiusMenuRow({required this.label, required this.selected});
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? c.primary : c.textPrimary,
            ),
          ),
        ),
        if (selected) Icon(LucideIcons.check, size: 18, color: c.primary),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sticky "Joylash" button — 48px, primary, Shadow/xs (Figma `Buttons`).
// ---------------------------------------------------------------------------
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.label, required this.loading, required this.onPressed});
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.types;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Color(0x0D101828), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Material(
        color: onPressed == null ? c.primaryDisabled : c.primary,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(label, style: t.button.copyWith(color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small text-entry sheet for free-text fields (price, comment).
// ---------------------------------------------------------------------------
class _TextInputSheet extends StatefulWidget {
  const _TextInputSheet({
    required this.title,
    required this.initial,
    required this.keyboardType,
    required this.confirmLabel,
  });
  final String title;
  final String initial;
  final TextInputType keyboardType;
  final String confirmLabel;

  @override
  State<_TextInputSheet> createState() => _TextInputSheetState();
}

class _TextInputSheetState extends State<_TextInputSheet> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.types;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: c.gray300, borderRadius: BorderRadius.circular(999)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(widget.title, style: t.h3),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: widget.keyboardType,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(isDense: true),
              onSubmitted: (v) => Navigator.pop(context, v.trim()),
            ),
            const SizedBox(height: 16),
            DsButton(
              label: widget.confirmLabel,
              onPressed: () => Navigator.pop(context, _controller.text.trim()),
            ),
          ],
        ),
      ),
    );
  }
}
