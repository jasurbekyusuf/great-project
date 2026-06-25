import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/shared/design_system/ds_action_drawer.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';
import 'package:loadme_mobile/shared/design_system/ds_truck_type_drawer.dart';
import 'package:loadme_mobile/shared/widgets/frosted_header.dart';
import 'package:loadme_mobile/shared/widgets/select_location_drawer.dart';
import 'package:loadme_mobile/shared/widgets/swipe_back_wrapper.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Mirrors the Figma "Post truck" form (Garaj → node 6751-18148) 1:1. A carrier
// publishes a free truck for a route. The layout matches the Magnit form: info
// banner, route card (from/radius/to), transport picker, then a collapsible
// block of fields and a "Joylash" submit button.
class PostTruckFormScreen extends ConsumerStatefulWidget {
  const PostTruckFormScreen({super.key, this.postTruckId});
  final String? postTruckId;

  @override
  ConsumerState<PostTruckFormScreen> createState() => _PostTruckFormScreenState();
}

class _PostTruckFormScreenState extends ConsumerState<PostTruckFormScreen> {
  final _price = TextEditingController();
  final _comment = TextEditingController();
  final _maxWeight = TextEditingController();

  LocationItem? _from;
  LocationItem? _to;
  String? _radius;
  List<String> _transports = [];
  String? _cargoType;
  String? _period;
  bool _expanded = true;
  bool _submitting = false;

  @override
  void dispose() {
    _price.dispose();
    _comment.dispose();
    _maxWeight.dispose();
    super.dispose();
  }

  String? _loc(LocationItem? l) => l == null ? null : '${l.country} · ${l.title}';

  Future<void> _pickLocation({required bool isFrom}) async {
    final v = await showSelectLocationDrawer(
      context: context,
      isDestination: !isFrom,
      currentId: (isFrom ? _from : _to)?.id,
    );
    if (v != null) setState(() => isFrom ? _from = v : _to = v);
  }

  Future<void> _pickRadius() async {
    final v = await showDsActionDrawer<String>(
      context: context,
      title: 'magnit.radius'.tr(ref),
      currentValue: _radius,
      items: const [
        DsActionDrawerItem(value: '50', label: '50 km'),
        DsActionDrawerItem(value: '100', label: '100 km'),
        DsActionDrawerItem(value: '120', label: '120 km'),
        DsActionDrawerItem(value: '200', label: '200 km'),
        DsActionDrawerItem(value: '500', label: '500 km'),
      ],
    );
    if (v != null) setState(() => _radius = v);
  }

  Future<void> _pickTransport() async {
    final v = await showDsTruckTypeDrawer(
      context: context,
      initialSelected: _transports,
    );
    if (v != null) setState(() => _transports = v);
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

  Future<void> _confirmDelete() async {
    final c = context.colors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('form.deletePostTruckConfirm'.tr(ref)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr(ref)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('common.delete'.tr(ref), style: TextStyle(color: c.red700)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      context.canPop() ? context.pop() : context.go('/garage');
    }
  }

  Future<void> _submit() async {
    final errors = <String>[];
    if (_from == null) errors.add('${'magnit.from'.tr(ref)}: ${'magnit.choose'.tr(ref)}');
    if (_to == null) errors.add('${'magnit.to'.tr(ref)}: ${'magnit.choose'.tr(ref)}');
    if (_transports.isEmpty) {
      errors.add('${'magnit.transport'.tr(ref)}: ${'magnit.choose'.tr(ref)}');
    }
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errors.join('\n')), duration: const Duration(seconds: 4)),
      );
      return;
    }
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _submitting = false);
    context.canPop() ? context.pop() : context.go('/garage');
  }

  @override
  Widget build(BuildContext context) {
    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: FigmaPalette.sheetBg,
        body: Column(
          children: [
            // Title is the posted truck's identifier ("<owner> - <model>"); the
            // Figma sample value is kept verbatim until the garage data is wired.
            FrostedHeader(
              title: 'Magnit - ISUZU FVR34Q',
              trailing: InkResponse(
                onTap: _confirmDelete,
                radius: 20,
                child: const Icon(LucideIcons.trash2, size: 22, color: FigmaPalette.ink),
              ),
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                children: [
                  _InfoBanner(text: 'magnit.banner'.tr(ref)),
                  const SizedBox(height: 8),
                  _RouteCard(
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
                  _PostField(
                    icon: Icons.local_shipping_outlined,
                    label: 'magnit.transport'.tr(ref),
                    required: true,
                    value: _transports.isEmpty ? null : _transports.join(', '),
                    placeholder: 'magnit.transportHint'.tr(ref),
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
                    _PostField(
                      icon: Icons.crop_free_rounded,
                      label: 'magnit.cargoType'.tr(ref),
                      value: _cargoType == null ? null : 'magnit.cargo.${_cargoType!}'.tr(ref),
                      placeholder: 'magnit.choose'.tr(ref),
                      onTap: _pickCargoType,
                    ),
                    const SizedBox(height: 8),
                    _PostField(
                      icon: Icons.pending_actions_outlined,
                      label: 'magnit.period'.tr(ref),
                      value: _period == null ? null : 'magnit.period.${_period!}'.tr(ref),
                      placeholder: 'magnit.periodHint'.tr(ref),
                      onTap: _pickPeriod,
                    ),
                    const SizedBox(height: 8),
                    _PostField(
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
                    _PostField(
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
                    _PostField(
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
                    required: true,
                    value: fromValue,
                    placeholder: fromHint,
                    onTap: onFrom,
                  ),
                ),
                const SizedBox(width: 14),
                Container(width: 1, color: c.border),
                const SizedBox(width: 14),
                SizedBox(
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
class _PostField extends StatelessWidget {
  const _PostField({
    required this.icon,
    required this.label,
    required this.placeholder,
    required this.onTap,
    this.value,
    this.required = false,
  });

  final IconData icon;
  final String label;
  final String placeholder;
  final VoidCallback onTap;
  final String? value;
  final bool required;

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
            required: required,
            value: value,
            placeholder: placeholder,
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
    this.required = false,
    this.chipSize = 32,
    this.chipRadius = 10,
  });

  final IconData? icon;
  final String label;
  final String placeholder;
  final String? value;
  final bool required;
  final double chipSize;
  final double chipRadius;
  final VoidCallback? onTap;

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
              RichText(
                text: TextSpan(
                  style: t.caption.copyWith(
                    fontWeight: FontWeight.w400,
                    height: 15 / 12,
                    color: const Color(0xFF0B1020),
                  ),
                  children: [
                    TextSpan(text: label),
                    if (required)
                      TextSpan(text: ' *', style: TextStyle(color: c.red700)),
                  ],
                ),
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
        Icon(LucideIcons.chevronRight, size: 18, color: c.textPrimary),
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
            height: 36,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: t.bodyMedium.copyWith(fontWeight: FontWeight.w400, color: const Color(0xFF0B1020))),
                const SizedBox(width: 6),
                Icon(
                  expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 20,
                  color: const Color(0xFF0B1020),
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
// Small text-entry sheet for free-text fields (price, weight, comment).
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
