import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_controller.dart';
import 'package:loadme_mobile/shared/design_system/ds_action_drawer.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';
import 'package:loadme_mobile/shared/design_system/ds_success_modal.dart';
import 'package:loadme_mobile/shared/design_system/ds_truck_type_drawer.dart';
import 'package:loadme_mobile/shared/widgets/app_svg_icon.dart';
import 'package:loadme_mobile/shared/widgets/calendar_sheet.dart';
import 'package:loadme_mobile/shared/widgets/cupertino_date_sheet.dart';
import 'package:loadme_mobile/shared/widgets/frosted_header.dart';
import 'package:loadme_mobile/shared/widgets/select_location_drawer.dart';
import 'package:loadme_mobile/shared/widgets/swipe_back_wrapper.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Figma "Yuk qo’shish" (Mening yuklarim section — collapsed 6804:11175 /
/// expanded 6779:14985). A [FrostedHeader] over a stack of white icon-box
/// cards: a grouped Qayerdan→Qayerga route card, then Transport / Narxi /
/// To’lov turi / Og’irlik-Hajm tiles and a split Jo’nash vaqti | To’liq/Dagruz
/// row, with a "Ko’proq" expander revealing the advanced fields. The earlier
/// Gen-A form (LoadMe logo bar + English section titles) is fully replaced.
class LoadFormScreen extends ConsumerStatefulWidget {
  const LoadFormScreen({super.key, this.loadId});
  final String? loadId;

  @override
  ConsumerState<LoadFormScreen> createState() => _LoadFormScreenState();
}

class _LoadFormScreenState extends ConsumerState<LoadFormScreen> {
  final _price = TextEditingController();
  final _weight = TextEditingController();
  final _volume = TextEditingController();
  final _product = TextEditingController();
  final _comment = TextEditingController();
  final _advance = TextEditingController();

  LocationItem? _from;
  LocationItem? _to;
  List<String> _selectedTrucks = [];
  String? _paymentType; // cash | card | banking
  String? _cargoPart; // all | full | partial
  DateTime? _departDate;
  TimeOfDay? _departTime;
  DateTime? _arriveDate;
  String? _viewFor; // all | carrier | broker
  String? _showDuration;
  bool _expanded = false;
  bool _submitting = false;

  // Value + unit selections (Narxi / Avans currency, Og'irlik / Hajm birligi).
  String _priceCurrency = 'so’m';
  String _advanceCurrency = 'so’m';
  String _weightUnit = 'tonna';
  String _volumeUnit = 'm³';

  bool get _isEdit => widget.loadId != null;

  @override
  void dispose() {
    _price.dispose();
    _weight.dispose();
    _volume.dispose();
    _product.dispose();
    _comment.dispose();
    _advance.dispose();
    super.dispose();
  }

  // ---- formatting / label helpers ----
  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _paymentLabel(String v) =>
      v == 'cash' ? 'Naqd' : (v == 'card' ? 'Karta' : 'Bank o’tkazmasi');
  String _viewerLabel(String v) => v == 'all'
      ? 'Hammasi'
      : (v == 'carrier' ? 'Haydovchi' : 'Logist');
  String _cargoPartLabel(String v) =>
      v == 'all' ? 'Hammasi' : (v == 'full' ? 'To’liq' : 'Dagruz');

  String _priceLabel() =>
      _price.text.isEmpty ? 'Narxni kiriting' : '${_price.text} $_priceCurrency';
  String _advanceLabel() => _advance.text.isEmpty
      ? 'Avansni kiriting'
      : '${_advance.text} $_advanceCurrency';

  String _weightVolumeLabel() {
    if (_weight.text.isEmpty && _volume.text.isEmpty) return 'Tonna/m³';
    final w = _weight.text.isEmpty ? '—' : '${_weight.text} $_weightUnit';
    final v = _volume.text.isEmpty ? '—' : '${_volume.text} $_volumeUnit';
    return '$w / $v';
  }

  String _departLabel() {
    if (_departDate == null) return 'Kiriting';
    final base = _fmtDate(_departDate!);
    return _departTime == null ? base : '$base ${_fmtTime(_departTime!)}';
  }

  // ---- pickers ----
  Future<void> _pickLocation({required bool isFrom}) async {
    final v = await showSelectLocationDrawer(
      context: context,
      isDestination: !isFrom,
      currentId: (isFrom ? _from : _to)?.id,
    );
    if (v != null) {
      setState(() {
        if (isFrom) {
          _from = v;
        } else {
          _to = v;
        }
      });
    }
  }

  Future<void> _pickTruckType() async {
    final v = await showDsTruckTypeDrawer(
      context: context,
      initialSelected: _selectedTrucks,
    );
    if (v != null) setState(() => _selectedTrucks = v);
  }

  Future<void> _pickPaymentType() async {
    final v = await showDsSelectSheet<String>(
      context: context,
      title: 'To’lov turi',
      currentValue: _paymentType,
      saveLabel: 'Tayyor',
      items: const [
        DsSelectItem(value: 'cash', label: 'Naqd'),
        DsSelectItem(value: 'card', label: 'Karta'),
        DsSelectItem(value: 'banking', label: 'Bank o’tkazmasi'),
      ],
    );
    if (v != null) setState(() => _paymentType = v);
  }

  Future<void> _pickCargoPart() async {
    final v = await showDsSelectSheet<String>(
      context: context,
      title: 'To’liq/Dagruz',
      currentValue: _cargoPart,
      saveLabel: 'Tayyor',
      items: const [
        DsSelectItem(value: 'all', label: 'Hammasi'),
        DsSelectItem(value: 'full', label: 'To’liq'),
        DsSelectItem(value: 'partial', label: 'Dagruz'),
      ],
    );
    if (v != null) setState(() => _cargoPart = v);
  }

  Future<void> _pickViewer() async {
    final v = await showDsSelectSheet<String>(
      context: context,
      title: 'E’lonni kimlarga ko’rsatamiz?',
      currentValue: _viewFor,
      saveLabel: 'Tayyor',
      items: const [
        DsSelectItem(value: 'all', label: 'Hammasi'),
        DsSelectItem(value: 'carrier', label: 'Haydovchi'),
        DsSelectItem(value: 'broker', label: 'Logist'),
      ],
    );
    if (v != null) setState(() => _viewFor = v);
  }

  Future<void> _pickDuration() async {
    final v = await showDsSelectSheet<String>(
      context: context,
      title: 'E’lonni ko’rsatish muddati',
      currentValue: _showDuration,
      saveLabel: 'Tayyor',
      items: const [
        DsSelectItem(value: '1 kun', label: '1 kun'),
        DsSelectItem(value: '3 kun', label: '3 kun'),
        DsSelectItem(value: '1 hafta', label: '1 hafta'),
        DsSelectItem(value: '10 kun', label: '10 kun'),
      ],
    );
    if (v != null) setState(() => _showDuration = v);
  }

  Future<void> _pickDepart() async {
    final now = DateTime.now();
    final d = await showDsCalendarSheet(
      context,
      initial: _departDate ?? now,
      minimum: DateTime(now.year, now.month, now.day),
      maximum: now.add(const Duration(days: 365)),
    );
    if (d == null || !mounted) return;
    final t = await showCupertinoTimeSheet(
      context,
      title: 'Jo’nash vaqti',
      initial: _departTime ?? TimeOfDay.now(),
    );
    setState(() {
      _departDate = d;
      if (t != null) _departTime = t;
    });
  }

  Future<void> _pickArrive() async {
    final now = DateTime.now();
    final d = await showDsCalendarSheet(
      context,
      initial: _arriveDate ?? _departDate ?? now,
      minimum: _departDate ?? DateTime(now.year, now.month, now.day),
      maximum: now.add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _arriveDate = d);
  }

  // ---- value + unit inputs (Figma 6810:18284 — input box + unit dropdown) ----
  Future<void> _editPrice() async {
    final spec = _UnitFieldSpec(
      controller: _price,
      unit: _priceCurrency,
      units: const ['so’m', 'USD', 'EUR', 'RUB'],
      hint: 'Narxni kiriting',
    );
    final ok = await _showValueUnitSheet(title: 'Narxni kiriting', specs: [spec]);
    if (ok == true) setState(() => _priceCurrency = spec.unit);
  }

  Future<void> _editAdvance() async {
    final spec = _UnitFieldSpec(
      controller: _advance,
      unit: _advanceCurrency,
      units: const ['so’m', 'USD', 'EUR', 'RUB'],
      hint: 'Avansni kiriting',
    );
    final ok = await _showValueUnitSheet(title: 'Avansni kiriting', specs: [spec]);
    if (ok == true) setState(() => _advanceCurrency = spec.unit);
  }

  Future<void> _editWeightVolume() async {
    final w = _UnitFieldSpec(
      controller: _weight,
      unit: _weightUnit,
      units: const ['tonna', 'kg'],
      hint: 'Og’irlik',
      unitBoxWidth: 96,
    );
    final v = _UnitFieldSpec(
      controller: _volume,
      unit: _volumeUnit,
      units: const ['m³', 'litr'],
      hint: 'Hajm',
      unitBoxWidth: 96,
    );
    final ok =
        await _showValueUnitSheet(title: 'Og’irlik / Hajm', specs: [w, v]);
    if (ok == true) {
      setState(() {
        _weightUnit = w.unit;
        _volumeUnit = v.unit;
      });
    }
  }

  Future<bool?> _showValueUnitSheet({
    required String title,
    required List<_UnitFieldSpec> specs,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FigmaPalette.pageBg,
      barrierColor: Colors.black.withValues(alpha: 0.40),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _ValueUnitSheet(title: title, specs: specs),
    );
  }

  Future<void> _editProduct() async {
    final ok = await _showFieldsSheet(
      title: 'Nima yuklaymiz?',
      fields: [_SheetField(controller: _product, hint: 'Mahsulot nomi')],
    );
    if (ok == true) setState(() {});
  }

  Future<void> _editComment() async {
    final ok = await _showFieldsSheet(
      title: 'Izoh',
      fields: [
        _SheetField(controller: _comment, hint: 'Izoh kiriting', maxLines: 4)
      ],
    );
    if (ok == true) setState(() {});
  }

  void _pickFile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fayl yuklash tez orada qo’shiladi')),
    );
  }

  Future<bool?> _showFieldsSheet({
    required String title,
    required List<_SheetField> fields,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        final children = <Widget>[];
        for (var i = 0; i < fields.length; i++) {
          final f = fields[i];
          if (i > 0) children.add(const SizedBox(height: 12));
          children.add(Container(
            decoration: BoxDecoration(
              color: FigmaPalette.sheetBg,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: f.controller,
              autofocus: i == 0,
              minLines: f.maxLines > 1 ? 3 : 1,
              maxLines: f.maxLines,
              style: const TextStyle(fontSize: 16, color: FigmaPalette.ink),
              decoration: InputDecoration(
                hintText: f.hint,
                hintStyle: const TextStyle(color: FigmaPalette.label),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ));
        }
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: FigmaPalette.divider,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: FigmaPalette.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...children,
                const SizedBox(height: 16),
                DsButton(
                    label: 'Saqlash',
                    onPressed: () => Navigator.pop(ctx, true)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---- submit ----
  bool get _formValid =>
      _from != null && _to != null && _selectedTrucks.isNotEmpty;

  Future<void> _submit() async {
    if (!_formValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Iltimos majburiy maydonlarni to’ldiring')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(loadsControllerProvider.notifier).saveLoad(
            loadId: widget.loadId,
            fromAddress: '${_from!.country} · ${_from!.title}',
            toAddress: '${_to!.country} · ${_to!.title}',
            comment: _comment.text.trim(),
          );
      if (!mounted) return;
      await showDsSuccessModal(
        context,
        title: 'Muvaffaqiyatli',
        message: 'Yuk e’loningiz joylandi',
        actionLabel: 'Mening yuklarim',
        onAction: () => context.go('/my-loads'),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
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
            FrostedHeader(title: _isEdit ? 'Yukni tahrirlash' : 'Yuk qo’shish'),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                children: [
                  _routeCard(),
                  const SizedBox(height: 8),
                  _Tile(
                    icon: LucideIcons.truck,
                    label: 'Transport',
                    isRequired: true,
                    placeholder: _selectedTrucks.isEmpty,
                    value: _selectedTrucks.isEmpty
                        ? 'Transport turini tanlang'
                        : _selectedTrucks.join(', '),
                    onTap: _pickTruckType,
                  ),
                  const SizedBox(height: 8),
                  _Tile(
                    icon: LucideIcons.circleDollarSign,
                    label: 'Narxi',
                    placeholder: _price.text.isEmpty,
                    value: _priceLabel(),
                    onTap: _editPrice,
                  ),
                  const SizedBox(height: 8),
                  _Tile(
                    icon: LucideIcons.banknote,
                    label: 'To’lov turi',
                    placeholder: _paymentType == null,
                    value: _paymentType == null
                        ? 'To’lov turini tanlang'
                        : _paymentLabel(_paymentType!),
                    onTap: _pickPaymentType,
                  ),
                  const SizedBox(height: 8),
                  _Tile(
                    icon: LucideIcons.weight,
                    label: 'Og’irlik/Hajm',
                    placeholder: _weight.text.isEmpty && _volume.text.isEmpty,
                    value: _weightVolumeLabel(),
                    onTap: _editWeightVolume,
                  ),
                  const SizedBox(height: 8),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _Tile(
                            icon: LucideIcons.calendar,
                            label: 'Jo’nash vaqti',
                            placeholder: _departDate == null,
                            value: _departLabel(),
                            onTap: _pickDepart,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _Tile(
                            icon: LucideIcons.scan,
                            label: 'To’liq/Dagruz',
                            placeholder: _cargoPart == null,
                            value: _cargoPart == null
                                ? 'Tanlang'
                                : _cargoPartLabel(_cargoPart!),
                            onTap: _pickCargoPart,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MoreButton(
                    expanded: _expanded,
                    onTap: () => setState(() => _expanded = !_expanded),
                  ),
                  if (_expanded) ...[
                    const SizedBox(height: 8),
                    _Tile(
                      icon: LucideIcons.banknoteArrowUp,
                      label: 'Avans',
                      placeholder: _advance.text.isEmpty,
                      value: _advanceLabel(),
                      onTap: _editAdvance,
                    ),
                    const SizedBox(height: 8),
                    _Tile(
                      icon: LucideIcons.user,
                      label: 'E’lonni kimlarga ko’rsatamiz?',
                      placeholder: _viewFor == null,
                      value: _viewFor == null
                          ? 'Tanlang'
                          : _viewerLabel(_viewFor!),
                      onTap: _pickViewer,
                    ),
                    const SizedBox(height: 8),
                    _Tile(
                      icon: LucideIcons.clipboardClock,
                      label: 'E’lonni ko’rsatish muddati',
                      placeholder: _showDuration == null,
                      value: _showDuration ?? 'Muddatni tanlang',
                      onTap: _pickDuration,
                    ),
                    const SizedBox(height: 8),
                    _Tile(
                      icon: LucideIcons.calendar,
                      label: 'Yetib borish sanasi',
                      placeholder: _arriveDate == null,
                      value: _arriveDate == null
                          ? 'Kiriting'
                          : _fmtDate(_arriveDate!),
                      onTap: _pickArrive,
                    ),
                    const SizedBox(height: 8),
                    _Tile(
                      icon: LucideIcons.package,
                      label: 'Nima yuklaymiz?',
                      placeholder: _product.text.isEmpty,
                      value: _product.text.isEmpty
                          ? 'Mahsulot nomi'
                          : _product.text,
                      onTap: _editProduct,
                    ),
                    const SizedBox(height: 8),
                    _Tile(
                      icon: LucideIcons.fileUp,
                      label: 'Fayl',
                      placeholder: true,
                      value: 'Fayl yuklang',
                      onTap: _pickFile,
                    ),
                    const SizedBox(height: 8),
                    _Tile(
                      icon: LucideIcons.messageSquare,
                      label: 'Izoh',
                      placeholder: _comment.text.isEmpty,
                      value: _comment.text.isEmpty
                          ? 'Izoh kiriting'
                          : _comment.text,
                      onTap: _editComment,
                    ),
                  ],
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: DsButton(
                  label: 'Saqlash',
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

  // Grouped Qayerdan→Qayerga card with a cube → flag dotted rail.
  Widget _routeCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                _IconBox(
                  size: 36,
                  radius: 12,
                  child: appSvgIcon('card_cube',
                      size: 20, color: FigmaPalette.primary),
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Center(child: _VDottedLine()),
                  ),
                ),
                _IconBox(
                  size: 36,
                  radius: 12,
                  child: appSvgIcon('card_flag',
                      size: 20, color: FigmaPalette.primary),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Field(
                    label: 'Qayerdan',
                    isRequired: true,
                    placeholder: _from == null,
                    value: _from?.title ?? 'Yuk olish manzili',
                    onTap: () => _pickLocation(isFrom: true),
                  ),
                  const SizedBox(height: 10),
                  const Divider(
                      height: 1, thickness: 1, color: Color(0xFFD5D9E1)),
                  const SizedBox(height: 10),
                  _Field(
                    label: 'Qayerga',
                    isRequired: true,
                    placeholder: _to == null,
                    value: _to?.title ?? 'Yetkazish manzili',
                    onTap: () => _pickLocation(isFrom: false),
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

// ---------------------------------------------------------------------------
// Shared bits (mirror loads_filters_screen so the redesign stays consistent)
// ---------------------------------------------------------------------------

const _labelStyle = TextStyle(
  fontSize: 12,
  height: 14.52 / 12,
  fontWeight: FontWeight.w400,
  color: FigmaPalette.countLabel,
);
const _valueStyle = TextStyle(
  fontSize: 16,
  height: 24 / 16,
  fontWeight: FontWeight.w500,
  color: FigmaPalette.ink,
);
const _hintStyle = TextStyle(
  fontSize: 16,
  height: 24 / 16,
  fontWeight: FontWeight.w400,
  color: FigmaPalette.label,
);

class _SheetField {
  _SheetField({
    required this.controller,
    this.hint,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String? hint;
  final int maxLines;
}

/// Label-over-value with a trailing chevron and optional red required marker.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    required this.placeholder,
    this.isRequired = false,
    this.onTap,
  });

  final String label;
  final String value;
  final bool placeholder;
  final bool isRequired;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  text: label,
                  style: _labelStyle,
                  children: isRequired
                      ? const [
                          TextSpan(
                            text: ' *',
                            style: TextStyle(
                              fontSize: 12,
                              height: 14.52 / 12,
                              fontWeight: FontWeight.w400,
                              color: FigmaPalette.dangerText,
                            ),
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: placeholder ? _hintStyle : _valueStyle,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        const Icon(LucideIcons.chevronRight, size: 18, color: FigmaPalette.ink),
      ],
    );
    if (onTap == null) return row;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: row,
    );
  }
}

/// Light blue-gray rounded square holding a blue glyph. Figma uses 32×32 r10
/// for the field tiles and 36×36 r12 for the grouped route card.
class _IconBox extends StatelessWidget {
  const _IconBox({required this.child, this.size = 32, this.radius = 10});
  final Widget child;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEAEFF5),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}

/// White r16 card: icon-box · label-over-value · chevron. The whole tile is
/// hittable (icon included).
class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.isRequired = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool placeholder;
  final bool isRequired;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            _IconBox(child: Icon(icon, size: 20, color: FigmaPalette.primary)),
            const SizedBox(width: 12),
            Expanded(
              child: _Field(
                label: label,
                value: value,
                placeholder: placeholder,
                isRequired: isRequired,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Ko’proq ⌄" / "Yopish ⌃" expander — white r16 card, blue centered label.
class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.expanded, required this.onTap});
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              expanded ? 'Yopish' : 'Ko’proq',
              style: const TextStyle(
                fontSize: 16,
                height: 20 / 16,
                fontWeight: FontWeight.w600,
                color: FigmaPalette.primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
              size: 20,
              color: FigmaPalette.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Vertical dotted line that fills its allotted height (cube → flag rail).
/// A bare [CustomPaint] reports `Size.zero` when it has neither a child nor an
/// explicit size, so the rail used to collapse to nothing — give it an
/// infinite height that the surrounding [Expanded] clamps to the gap height.
class _VDottedLine extends StatelessWidget {
  const _VDottedLine();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 2,
      height: double.infinity,
      child: CustomPaint(painter: _VDots()),
    );
  }
}

class _VDots extends CustomPainter {
  const _VDots();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = FigmaPalette.label
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dot = 2.0;
    const gap = 3.0;
    final x = size.width / 2;
    var y = 0.0;
    while (y < size.height) {
      final end = (y + dot) > size.height ? size.height : y + dot;
      canvas.drawLine(Offset(x, y), Offset(x, end), paint);
      y += dot + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _VDots oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Value + unit sheet — Figma "Narxni kiriting" (6810:18284). An X-close header,
// one or more [ value input | unit dropdown ] rows, and a pinned blue Saqlash
// button. Tapping the unit box opens a `showDsSelectSheet` to switch the unit.
// ---------------------------------------------------------------------------
class _UnitFieldSpec {
  _UnitFieldSpec({
    required this.controller,
    required this.unit,
    required this.units,
    this.hint,
    this.unitBoxWidth = 83,
  });

  final TextEditingController controller;
  String unit;
  final List<String> units;
  final String? hint;

  /// Width of the trailing unit dropdown box. Defaults to the Figma currency
  /// box (83). Wider unit labels (e.g. "tonna") pass a larger value so the text
  /// is never ellipsised and both boxes in a multi-row sheet stay aligned.
  final double unitBoxWidth;
}

class _ValueUnitSheet extends StatefulWidget {
  const _ValueUnitSheet({required this.title, required this.specs});
  final String title;
  final List<_UnitFieldSpec> specs;

  @override
  State<_ValueUnitSheet> createState() => _ValueUnitSheetState();
}

class _ValueUnitSheetState extends State<_ValueUnitSheet> {
  static const _blue = Color(0xFF004EEA);
  static const _titleColor = Color(0xFF0F1728);
  static const _valueColor = Color(0xFF131313);

  Future<void> _pickUnit(_UnitFieldSpec spec) async {
    final v = await showDsSelectSheet<String>(
      context: context,
      title: 'Birlikni tanlang',
      currentValue: spec.unit,
      saveLabel: 'Tayyor',
      items: [for (final u in spec.units) DsSelectItem(value: u, label: u)],
    );
    if (v != null) setState(() => spec.unit = v);
  }

  BoxDecoration get _boxDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _blue, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14101828), // #101828 @ 8%
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(context),
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: Icon(LucideIcons.x, size: 22, color: _titleColor),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 24 / 16,
                      fontWeight: FontWeight.w600,
                      color: _titleColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            for (var i = 0; i < widget.specs.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _row(widget.specs[i], autofocus: i == 0),
            ],
            const SizedBox(height: 24),
            _SheetSaveButton(
              label: 'Saqlash',
              onTap: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(_UnitFieldSpec spec, {required bool autofocus}) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Expanded(child: _valueBox(spec, autofocus)),
          const SizedBox(width: 12),
          _unitBox(spec),
        ],
      ),
    );
  }

  Widget _valueBox(_UnitFieldSpec spec, bool autofocus) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: _boxDecoration,
      child: TextField(
        controller: spec.controller,
        autofocus: autofocus,
        keyboardType: TextInputType.number,
        cursorColor: _blue,
        cursorWidth: 1.5,
        style: const TextStyle(
          fontSize: 16,
          height: 24 / 16,
          leadingDistribution: TextLeadingDistribution.even,
          color: _valueColor,
        ),
        decoration: InputDecoration(
          isCollapsed: true,
          filled: false,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: spec.hint,
          hintStyle: const TextStyle(
            fontSize: 16,
            height: 24 / 16,
            leadingDistribution: TextLeadingDistribution.even,
            color: FigmaPalette.label,
          ),
        ),
      ),
    );
  }

  Widget _unitBox(_UnitFieldSpec spec) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _pickUnit(spec),
      child: Container(
        width: spec.unitBoxWidth,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: _boxDecoration,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                spec.unit,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  height: 24 / 16,
                  leadingDistribution: TextLeadingDistribution.even,
                  color: _valueColor,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(LucideIcons.chevronDown,
                size: 18, color: Color(0xFF000000)),
          ],
        ),
      ),
    );
  }
}

class _SheetSaveButton extends StatelessWidget {
  const _SheetSaveButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF004EEA),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D101828), offset: Offset(0, 1), blurRadius: 2),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: 48,
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
