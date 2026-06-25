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

  LocationItem? _from;
  LocationItem? _to;
  List<String> _selectedTrucks = [];
  String? _paymentType; // cash | card | banking
  String? _cargoPart; // full | partial
  DateTime? _departDate;
  TimeOfDay? _departTime;
  DateTime? _arriveDate;
  String? _viewFor; // all | shipper | broker | carrier
  String? _showDuration;
  bool _expanded = false;
  bool _submitting = false;

  bool get _isEdit => widget.loadId != null;

  @override
  void dispose() {
    _price.dispose();
    _weight.dispose();
    _volume.dispose();
    _product.dispose();
    _comment.dispose();
    super.dispose();
  }

  // ---- formatting / label helpers ----
  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _paymentLabel(String v) =>
      v == 'cash' ? 'Naqd' : (v == 'card' ? 'Karta' : 'Bank o’tkazma');
  String _viewerLabel(String v) => v == 'all'
      ? 'Hammasi'
      : (v == 'shipper'
          ? 'Yuk egasi'
          : (v == 'broker' ? 'Broker' : 'Tashuvchi'));

  String _weightVolumeLabel() {
    if (_weight.text.isEmpty && _volume.text.isEmpty) return 'Tonna/m³';
    final w = _weight.text.isEmpty ? '—' : '${_weight.text} t';
    final v = _volume.text.isEmpty ? '—' : '${_volume.text} m³';
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
    final v = await showDsActionDrawer<String>(
      context: context,
      title: 'To’lov turi',
      currentValue: _paymentType,
      items: const [
        DsActionDrawerItem(value: 'cash', label: 'Naqd'),
        DsActionDrawerItem(value: 'card', label: 'Karta'),
        DsActionDrawerItem(value: 'banking', label: 'Bank o’tkazma'),
      ],
    );
    if (v != null) setState(() => _paymentType = v);
  }

  Future<void> _pickCargoPart() async {
    final v = await showDsActionDrawer<String>(
      context: context,
      title: 'To’liq/Dagruz',
      currentValue: _cargoPart,
      items: const [
        DsActionDrawerItem(value: 'full', label: 'To’liq'),
        DsActionDrawerItem(value: 'partial', label: 'Dagruz'),
      ],
    );
    if (v != null) setState(() => _cargoPart = v);
  }

  Future<void> _pickViewer() async {
    final v = await showDsActionDrawer<String>(
      context: context,
      title: 'E’lonni kimlarga ko’rsatamiz?',
      currentValue: _viewFor,
      items: const [
        DsActionDrawerItem(value: 'all', label: 'Hammasi'),
        DsActionDrawerItem(value: 'shipper', label: 'Yuk egasi'),
        DsActionDrawerItem(value: 'broker', label: 'Broker'),
        DsActionDrawerItem(value: 'carrier', label: 'Tashuvchi'),
      ],
    );
    if (v != null) setState(() => _viewFor = v);
  }

  Future<void> _pickDuration() async {
    final v = await showDsActionDrawer<String>(
      context: context,
      title: 'E’lonni ko’rsatish muddati',
      currentValue: _showDuration,
      items: const [
        DsActionDrawerItem(value: '1 kun', label: '1 kun'),
        DsActionDrawerItem(value: '3 kun', label: '3 kun'),
        DsActionDrawerItem(value: '1 hafta', label: '1 hafta'),
        DsActionDrawerItem(value: '10 kun', label: '10 kun'),
      ],
    );
    if (v != null) setState(() => _showDuration = v);
  }

  Future<void> _pickDepart() async {
    final now = DateTime.now();
    final d = await showCupertinoDateSheet(
      context,
      title: 'Jo’nash sanasi',
      initial: _departDate ?? now,
      minimum: now.subtract(const Duration(days: 1)),
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
    final d = await showCupertinoDateSheet(
      context,
      title: 'Yetib borish sanasi',
      initial: _arriveDate ?? now,
      minimum: now.subtract(const Duration(days: 1)),
      maximum: now.add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _arriveDate = d);
  }

  // ---- free-text / number inputs (bottom sheet) ----
  Future<void> _editPrice() async {
    final ok = await _showFieldsSheet(
      title: 'Narxi',
      fields: [
        _SheetField(
            controller: _price,
            hint: 'Narxni kiriting',
            keyboardType: TextInputType.number),
      ],
    );
    if (ok == true) setState(() {});
  }

  Future<void> _editWeightVolume() async {
    final ok = await _showFieldsSheet(
      title: 'Og’irlik / Hajm',
      fields: [
        _SheetField(
            controller: _weight,
            label: 'Og’irlik (t)',
            hint: '0',
            keyboardType: TextInputType.number),
        _SheetField(
            controller: _volume,
            label: 'Hajm (m³)',
            hint: '0',
            keyboardType: TextInputType.number),
      ],
    );
    if (ok == true) setState(() {});
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
          if (f.label != null) {
            children
              ..add(Text(f.label!, style: _labelStyle))
              ..add(const SizedBox(height: 6));
          }
          children.add(Container(
            decoration: BoxDecoration(
              color: FigmaPalette.sheetBg,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: f.controller,
              autofocus: i == 0,
              keyboardType: f.keyboardType,
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
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
                  _Tile(
                    icon: LucideIcons.circleDollarSign,
                    label: 'Narxi',
                    placeholder: _price.text.isEmpty,
                    value:
                        _price.text.isEmpty ? 'Narxni kiriting' : _price.text,
                    onTap: _editPrice,
                  ),
                  const SizedBox(height: 12),
                  _Tile(
                    icon: LucideIcons.creditCard,
                    label: 'To’lov turi',
                    placeholder: _paymentType == null,
                    value: _paymentType == null
                        ? 'To’lov turini tanlang'
                        : _paymentLabel(_paymentType!),
                    onTap: _pickPaymentType,
                  ),
                  const SizedBox(height: 12),
                  _Tile(
                    icon: LucideIcons.weight,
                    label: 'Og’irlik/Hajm',
                    placeholder: _weight.text.isEmpty && _volume.text.isEmpty,
                    value: _weightVolumeLabel(),
                    onTap: _editWeightVolume,
                  ),
                  const SizedBox(height: 12),
                  Row(
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Tile(
                          icon: LucideIcons.scan,
                          label: 'To’liq/Dagruz',
                          placeholder: _cargoPart == null,
                          value: _cargoPart == null
                              ? 'Tanlang'
                              : (_cargoPart == 'full' ? 'To’liq' : 'Dagruz'),
                          onTap: _pickCargoPart,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _MoreButton(
                    expanded: _expanded,
                    onTap: () => setState(() => _expanded = !_expanded),
                  ),
                  if (_expanded) ...[
                    const SizedBox(height: 12),
                    _Tile(
                      icon: LucideIcons.user,
                      label: 'E’lonni kimlarga ko’rsatamiz?',
                      placeholder: _viewFor == null,
                      value: _viewFor == null
                          ? 'Tanlang'
                          : _viewerLabel(_viewFor!),
                      onTap: _pickViewer,
                    ),
                    const SizedBox(height: 12),
                    _Tile(
                      icon: LucideIcons.calendarClock,
                      label: 'E’lonni ko’rsatish muddati',
                      placeholder: _showDuration == null,
                      value: _showDuration ?? 'Muddatni tanlang',
                      onTap: _pickDuration,
                    ),
                    const SizedBox(height: 12),
                    _Tile(
                      icon: LucideIcons.calendarCheck,
                      label: 'Yetib borish sanasi',
                      placeholder: _arriveDate == null,
                      value: _arriveDate == null
                          ? 'Kiriting'
                          : _fmtDate(_arriveDate!),
                      onTap: _pickArrive,
                    ),
                    const SizedBox(height: 12),
                    _Tile(
                      icon: LucideIcons.fileText,
                      label: 'Nima yuklaymiz?',
                      placeholder: _product.text.isEmpty,
                      value: _product.text.isEmpty
                          ? 'Mahsulot nomi'
                          : _product.text,
                      onTap: _editProduct,
                    ),
                    const SizedBox(height: 12),
                    _Tile(
                      icon: LucideIcons.fileUp,
                      label: 'Fayl',
                      placeholder: true,
                      value: 'Fayl yuklang',
                      onTap: _pickFile,
                    ),
                    const SizedBox(height: 12),
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
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                _IconBox(
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
                      height: 1, thickness: 1, color: FigmaPalette.divider),
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
  height: 16 / 12,
  fontWeight: FontWeight.w500,
  color: FigmaPalette.gray700,
);
const _valueStyle = TextStyle(
  fontSize: 16,
  height: 20 / 16,
  fontWeight: FontWeight.w500,
  color: FigmaPalette.ink,
);
const _hintStyle = TextStyle(
  fontSize: 16,
  height: 20 / 16,
  fontWeight: FontWeight.w400,
  color: FigmaPalette.label,
);

class _SheetField {
  _SheetField({
    required this.controller,
    this.label,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final TextInputType keyboardType;
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
                              height: 16 / 12,
                              fontWeight: FontWeight.w500,
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

/// 40×40 light-gray rounded square holding a blue glyph.
class _IconBox extends StatelessWidget {
  const _IconBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: FigmaPalette.chipBg,
        borderRadius: BorderRadius.circular(12),
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
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            _IconBox(child: Icon(icon, size: 22, color: FigmaPalette.primary)),
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
class _VDottedLine extends StatelessWidget {
  const _VDottedLine();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 2, child: CustomPaint(painter: _VDots()));
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
