import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
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
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();
  final _measureController = TextEditingController();

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
    _modelController.dispose();
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
                    context.canPop() ? context.pop() : context.go('/my-trucks'),
              ),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  children: [
                    _InputTile(
                      icon: LucideIcons.hexagon,
                      label: 'Transport modeli',
                      hint: 'Modelni kiriting',
                      controller: _modelController,
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
                    _InputTile(
                      icon: LucideIcons.hash,
                      label: 'Transport raqami',
                      hint: 'Raqamni kiriting',
                      controller: _plateController,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    _InputTile(
                      icon: LucideIcons.weight,
                      label: "Og'irlik/Hajm",
                      hint: 'Tonna/m³',
                      controller: _measureController,
                      keyboardType: TextInputType.number,
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
    if (_modelController.text.trim().isEmpty) errors.add('Model: kiritish kerak');
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
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _submitting = false);
    context.go('/my-trucks');
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

class _InputTile extends StatelessWidget {
  const _InputTile({
    required this.icon,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
  });

  final IconData icon;
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return _Tile(
      icon: icon,
      label: label,
      value: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        onChanged: onChanged,
        style: _valueStyle,
        cursorColor: FigmaPalette.primary,
        // Borderless: the app's inputDecorationTheme would otherwise draw an
        // outline (collapsed only nulls `border`, not enabled/focused).
        decoration: InputDecoration(
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: hint,
          hintStyle: _hintStyle,
        ),
      ),
    );
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
