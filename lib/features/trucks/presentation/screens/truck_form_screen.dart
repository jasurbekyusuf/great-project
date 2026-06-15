import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/features/garage/presentation/providers/garage_providers.dart';
import 'package:loadme_mobile/shared/design_system/ds_action_drawer.dart';
import 'package:loadme_mobile/shared/widgets/swipe_back_wrapper.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// "Transport qo'shish" — pixel port of Figma node 6542:42454.
///   • bg #F3F4F7, white tile fields (icon-box + label + value + chevron)
///   • vehicle image card (photo + plate chip + edit pencil)
///   • sticky blue "Saqlash" button
class TruckFormScreen extends ConsumerStatefulWidget {
  const TruckFormScreen({super.key, this.truckId});

  final String? truckId;

  @override
  ConsumerState<TruckFormScreen> createState() => _TruckFormScreenState();
}

class _TruckFormScreenState extends ConsumerState<TruckFormScreen> {
  final _plateController = TextEditingController();
  final _measureController = TextEditingController();

  String? _model;
  String? _truckType;
  String? _photoUrl;
  var _submitting = false;

  static const _truckTypes = [
    'Tent / Shtora', 'Refrigerator', 'Isuzu NQR / NPR', 'Trailer',
    "Container 20'", "Container 40'", 'Flatbed',
  ];

  bool get _isEdit => widget.truckId != null;

  @override
  void dispose() {
    _plateController.dispose();
    _measureController.dispose();
    super.dispose();
  }

  Future<void> _pickTruckType() async {
    final v = await showDsActionDrawer<String>(
      context: context,
      title: 'Transport turi',
      currentValue: _truckType,
      items:
          _truckTypes.map((t) => DsActionDrawerItem(value: t, label: t)).toList(),
    );
    if (v != null) setState(() => _truckType = v);
  }

  Future<void> _pickModel() async {
    final v = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => const _ModelPickerSheet(),
    );
    if (v != null) setState(() => _model = v);
  }

  Future<void> _pickPlate() async {
    final v = await showPlateInput(context, _plateController.text);
    if (v != null) setState(() => _plateController.text = v);
  }

  Future<void> _pickCapacity() async {
    final v = await showCapacityInput(context, _measureController.text);
    if (v != null) setState(() => _measureController.text = v);
  }

  void _pickPhoto() {
    // Demo upload — swap in a real picker later.
    setState(() => _photoUrl =
        'https://picsum.photos/seed/truck${DateTime.now().millisecond}/800/520');
  }

  @override
  Widget build(BuildContext context) {
    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: FigmaPalette.sheetBg,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _Header(
                title: (_isEdit ? 'form.editTruckTitle' : 'form.addTruckTitle')
                    .tr(ref),
                onBack: () =>
                    context.canPop() ? context.pop() : context.go('/garage'),
              ),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  children: [
                    _SelectTile(
                      icon: LucideIcons.hexagon,
                      label: 'Transport modeli',
                      hint: 'Modelni kiriting',
                      value: _model,
                      onTap: _pickModel,
                    ),
                    const SizedBox(height: 8),
                    _SelectTile(
                      icon: LucideIcons.truck,
                      label: 'Transport turi',
                      hint: 'Transportni tanlang',
                      value: _truckType,
                      onTap: _pickTruckType,
                    ),
                    const SizedBox(height: 8),
                    _SelectTile(
                      icon: LucideIcons.hash,
                      label: 'Transport raqami',
                      hint: 'Raqamni kiriting',
                      value: _plateController.text.isEmpty
                          ? null
                          : _plateController.text,
                      onTap: _pickPlate,
                    ),
                    const SizedBox(height: 8),
                    _SelectTile(
                      icon: LucideIcons.weight,
                      label: 'Maksimum yuk olish quvvati',
                      hint: 'Quvvatni kiriting',
                      value: _measureController.text.isEmpty
                          ? null
                          : _measureController.text,
                      onTap: _pickCapacity,
                    ),
                    const SizedBox(height: 16),
                    _VehicleImageCard(
                      photoUrl: _photoUrl,
                      plate: _plateController.text,
                      onEdit: _pickPhoto,
                    ),
                  ],
                ),
              ),
              _SubmitBar(
                label: 'common.save'.tr(ref),
                loading: _submitting,
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final errors = <String>[];
    if (_model == null) errors.add('Model: tanlash kerak');
    if (_truckType == null) errors.add('Transport turi: tanlash kerak');
    if (_plateController.text.trim().isEmpty) {
      errors.add('Transport raqami: kiritish kerak');
    }
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(errors.join('\n')),
            duration: const Duration(seconds: 4)),
      );
      return;
    }

    setState(() => _submitting = true);
    if (!_isEdit) {
      // Add the new vehicle to the garage and refresh the Transportlar list.
      await ref.read(garageRepositoryProvider).addVehicle(
            GarageVehicle(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              name: _model ?? '',
              model: _truckType ?? '',
              plate: _plateController.text.trim(),
              photoUrl: _photoUrl,
            ),
          );
      ref.invalidate(garageVehiclesProvider);
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
    if (!mounted) return;
    setState(() => _submitting = false);
    // Return to where it was opened from (the Garaj tab); fall back to /garage.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/garage');
    }
  }
}

// ---------------------------------------------------------------------------
// Header — back · "Transport qo'shish" · bookmark
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _IconBtn(icon: LucideIcons.chevronLeft, onTap: onBack),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: FigmaPalette.ink,
                  ),
                ),
              ),
              _IconBtn(icon: LucideIcons.bookmark, onTap: () {}),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, size: 22, color: FigmaPalette.ink),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Field tiles — icon-box + label + value + chevron (Figma `Frame 2087329800`)
// ---------------------------------------------------------------------------

const _iconBoxBg = Color(0xFFEBEBEB);

const _labelStyle = TextStyle(
  fontSize: 12,
  height: 14.5 / 12,
  fontWeight: FontWeight.w400,
  color: FigmaPalette.countLabel, // #0B1020
);
const _valueStyle = TextStyle(
  fontSize: 16,
  height: 24 / 16,
  fontWeight: FontWeight.w400,
  color: FigmaPalette.ink,
);
const _hintStyle = TextStyle(
  fontSize: 16,
  height: 24 / 16,
  fontWeight: FontWeight.w400,
  color: FigmaPalette.label, // #98A2B3
);

/// Shared tile shell: white r12, icon-box, label + [value], trailing chevron.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _iconBoxBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: FigmaPalette.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: _labelStyle),
                const SizedBox(height: 2),
                value,
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(LucideIcons.chevronRight,
              size: 18, color: FigmaPalette.label),
        ],
      ),
    );
    if (onTap == null) return tile;
    return GestureDetector(
        onTap: onTap, behavior: HitTestBehavior.opaque, child: tile);
  }
}

class _SelectTile extends StatelessWidget {
  const _SelectTile({
    required this.icon,
    required this.label,
    required this.hint,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Tile(
      icon: icon,
      label: label,
      onTap: onTap,
      value: Text(
        value ?? hint,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: value == null ? _hintStyle : _valueStyle,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Model picker — searchable bottom sheet (Figma node 6564:43930)
// ---------------------------------------------------------------------------

class _ModelPickerSheet extends StatefulWidget {
  const _ModelPickerSheet();

  @override
  State<_ModelPickerSheet> createState() => _ModelPickerSheetState();
}

class _ModelPickerSheetState extends State<_ModelPickerSheet> {
  static const _models = [
    'Volvo FH',
    'Mercedes-Benz Actros',
    'MAN TGX',
    'Scania S-series',
    'DAF XF',
    'KAMAZ 54901 (K5)',
    'MAZ 5440',
    'GAZ GAZon NEXT',
    'Howo (Sinotruk) TX / Max',
  ];

  final _search = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim();
    final filtered = _models
        .where((m) => m.toLowerCase().contains(q.toLowerCase()))
        .toList();
    final canAdd =
        q.isNotEmpty && !_models.any((m) => m.toLowerCase() == q.toLowerCase());
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                'Transport modeli',
                style: TextStyle(
                  fontSize: 18,
                  height: 24 / 18,
                  fontWeight: FontWeight.w600,
                  color: FigmaPalette.ink,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _search,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Qidiruv',
                prefixIcon: Icon(LucideIcons.search, size: 18),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: filtered.length + (canAdd ? 1 : 0),
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: FigmaPalette.divider),
                itemBuilder: (_, i) {
                  // Figma 6564:44873 — let an unlisted model be added.
                  if (canAdd && i == 0) {
                    return InkWell(
                      onTap: () => Navigator.pop(context, q),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.plus,
                                size: 18, color: FigmaPalette.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ro’yxatga qo’shish: «$q»',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 24 / 16,
                                  fontWeight: FontWeight.w500,
                                  color: FigmaPalette.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final model = filtered[i - (canAdd ? 1 : 0)];
                  return InkWell(
                    onTap: () => Navigator.pop(context, model),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 14,
                      ),
                      child: Text(
                        model,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 24 / 16,
                          fontWeight: FontWeight.w500,
                          color: FigmaPalette.ink,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Transport raqami — Uzbek license-plate input (Figma 6576:6489): a real-plate
// graphic with a numeric region cell + alpha-numeric body + UZ flag.
// ---------------------------------------------------------------------------

Future<String?> showPlateInput(BuildContext context, String initial) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute<String>(
      fullscreenDialog: true,
      builder: (_) => _PlateInputPage(initial: initial),
    ),
  );
}

class _PlateInputPage extends StatefulWidget {
  const _PlateInputPage({required this.initial});
  final String initial;

  @override
  State<_PlateInputPage> createState() => _PlateInputPageState();
}

class _PlateInputPageState extends State<_PlateInputPage> {
  late final TextEditingController _region;
  late final TextEditingController _body;

  @override
  void initState() {
    super.initState();
    // Split an existing "30 A 701 AS" into region ("30") + body ("A 701 AS").
    final parts = widget.initial.trim().split(RegExp(r'\s+'));
    if (parts.length > 1 && RegExp(r'^\d+$').hasMatch(parts.first)) {
      _region = TextEditingController(text: parts.first);
      _body = TextEditingController(text: parts.skip(1).join(' '));
    } else {
      _region = TextEditingController();
      _body = TextEditingController(text: widget.initial.trim());
    }
  }

  @override
  void dispose() {
    _region.dispose();
    _body.dispose();
    super.dispose();
  }

  void _save() {
    final plate = [_region.text.trim(), _body.text.trim().toUpperCase()]
        .where((e) => e.isNotEmpty)
        .join(' ');
    Navigator.pop(context, plate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FigmaPalette.sheetBg,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _IconBtn(
                      icon: LucideIcons.x,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Transport raqami',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: FigmaPalette.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _PlateField(region: _region, body: _body),
            ),
            const Spacer(),
            _SubmitBar(label: 'Saqlash', loading: false, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

/// The plate graphic: black-bordered white plate, numeric region cell, a
/// divider, the alpha-numeric body, and a small UZ flag.
class _PlateField extends StatelessWidget {
  const _PlateField({required this.region, required this.body});
  final TextEditingController region;
  final TextEditingController body;

  // Figma 6576:6489 — plate: outer 2px #000 r6; two white cells (1px #000, r5);
  // region "30" fs36, body "A 701 AS" fs52, UZ #1271A1.
  static const _regionStyle = TextStyle(
    fontSize: 36,
    height: 1,
    fontWeight: FontWeight.w700,
    color: Colors.black,
  );
  static const _bodyStyle = TextStyle(
    fontSize: 48,
    height: 1,
    fontWeight: FontWeight.w700,
    color: Colors.black,
    letterSpacing: 1,
  );

  InputDecoration _dec(String hint, TextStyle base) => InputDecoration(
        counterText: '',
        isCollapsed: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        hintText: hint,
        hintStyle: base.copyWith(color: const Color(0xFFC2C8D2)),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Colors.black),
            ),
            alignment: Alignment.center,
            child: TextField(
              controller: region,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              maxLength: 3,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: _regionStyle,
              cursorColor: Colors.black,
              decoration: _dec('30', _regionStyle),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.black),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: body,
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.center,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 10,
                      inputFormatters: [
                        TextInputFormatter.withFunction(
                          (o, n) => n.copyWith(text: n.text.toUpperCase()),
                        ),
                      ],
                      style: _bodyStyle,
                      cursorColor: Colors.black,
                      decoration: _dec('A 701 AS', _bodyStyle),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const _UzFlag(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UzFlag extends StatelessWidget {
  const _UzFlag();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: const SizedBox(
            width: 26,
            height: 17,
            child: Column(
              children: [
                Expanded(flex: 3, child: ColoredBox(color: Color(0xFF1EB4D4))),
                Expanded(child: ColoredBox(color: Color(0xFFCE1126))),
                Expanded(flex: 3, child: ColoredBox(color: Colors.white)),
                Expanded(child: ColoredBox(color: Color(0xFFCE1126))),
                Expanded(flex: 3, child: ColoredBox(color: Color(0xFF1EB53A))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 1),
        const Text(
          'UZ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1271A1),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Maksimum yuk olish quvvati — capacity input sheet (Figma 6585:18496):
// numeric value + Og'irlik / Hajm unit selector.
// ---------------------------------------------------------------------------

Future<String?> showCapacityInput(BuildContext context, String initial) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => _CapacitySheet(initial: initial),
  );
}

class _CapacitySheet extends StatefulWidget {
  const _CapacitySheet({required this.initial});
  final String initial;

  @override
  State<_CapacitySheet> createState() => _CapacitySheetState();
}

class _CapacitySheetState extends State<_CapacitySheet> {
  late final TextEditingController _value;
  late String _unit;

  @override
  void initState() {
    super.initState();
    final m = RegExp(r'[\d.,]+').firstMatch(widget.initial);
    _value = TextEditingController(text: m?.group(0) ?? '');
    _unit = widget.initial.contains('m³') ? 'Hajm' : "Og'irlik";
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  String get _hint => _unit == 'Hajm' ? 'm³' : 'tonna';
  String get _short => _unit == 'Hajm' ? 'm³' : 't';

  Future<void> _pickUnit() async {
    final v = await showDsActionDrawer<String>(
      context: context,
      title: 'Birlik',
      currentValue: _unit,
      items: const [
        DsActionDrawerItem(value: "Og'irlik", label: "Og'irlik (tonna)"),
        DsActionDrawerItem(value: 'Hajm', label: 'Hajm (m³)'),
      ],
    );
    if (v != null) setState(() => _unit = v);
  }

  void _save() {
    final v = _value.text.trim();
    Navigator.pop(context, v.isEmpty ? '' : '$v $_short');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
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
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  behavior: HitTestBehavior.opaque,
                  child: const Icon(LucideIcons.x,
                      size: 22, color: FigmaPalette.ink),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Maksimum yuk olish quvvati',
                  style: TextStyle(
                    fontSize: 18,
                    height: 24 / 18,
                    fontWeight: FontWeight.w600,
                    color: FigmaPalette.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FigmaPalette.primary),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _value,
                      autofocus: true,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                      ],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: FigmaPalette.ink,
                      ),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: _hint,
                        hintStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: FigmaPalette.label,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _pickUnit,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        Text(
                          _unit,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: FigmaPalette.gray700,
                          ),
                        ),
                        const Icon(LucideIcons.chevronDown,
                            size: 18, color: FigmaPalette.gray700),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SubmitBar(label: 'Saqlash', loading: false, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vehicle image card — photo + plate chip + edit pencil (Figma `Frame …804`)
// ---------------------------------------------------------------------------

class _VehicleImageCard extends StatelessWidget {
  const _VehicleImageCard({
    required this.photoUrl,
    required this.plate,
    required this.onEdit,
  });

  final String? photoUrl;
  final String plate;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 343 / 223.6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photoUrl != null)
              Image.network(photoUrl!, fit: BoxFit.cover)
            else
              const ColoredBox(
                color: Color(0xFFE5E7EB),
                child: Center(
                  child: Icon(LucideIcons.truck,
                      size: 56, color: FigmaPalette.muted),
                ),
              ),
            Positioned(
              left: 12,
              bottom: 12,
              child: _PlateChip(plate: plate),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: _EditButton(onTap: onEdit),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const SizedBox(
          width: 28,
          height: 28,
          child: Icon(LucideIcons.pencil, size: 15, color: Color(0xFF101828)),
        ),
      ),
    );
  }
}

/// Compact Uzbek-style number plate: region box + number box (+ "UZ").
class _PlateChip extends StatelessWidget {
  const _PlateChip({required this.plate});
  final String plate;

  @override
  Widget build(BuildContext context) {
    final t = plate.trim();
    final parts = t.isEmpty ? const ['30', 'A 701 AS'] : t.split(RegExp(r'\s+'));
    final region = parts.first;
    final number = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg(Text(region,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black))),
          const SizedBox(width: 2),
          _seg(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (number.isNotEmpty)
                Text(number,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black)),
              if (number.isNotEmpty) const SizedBox(width: 4),
              const Text('UZ',
                  style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1271A1))),
            ],
          )),
        ],
      ),
    );
  }

  Widget _seg(Widget child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
        ),
        child: child,
      );
}

// ---------------------------------------------------------------------------
// Sticky submit
// ---------------------------------------------------------------------------

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Material(
          color: FigmaPalette.primary,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 48,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
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
        ),
      ),
    );
  }
}
