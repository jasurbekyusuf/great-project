import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_controller.dart';
import 'package:loadme_mobile/features/loads/presentation/widgets/add_load_fields.dart';
import 'package:loadme_mobile/shared/design_system/ds_action_drawer.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';
import 'package:loadme_mobile/shared/design_system/ds_success_modal.dart';
import 'package:loadme_mobile/shared/widgets/cupertino_date_sheet.dart';
import 'package:loadme_mobile/shared/widgets/select_location_drawer.dart';
import 'package:loadme_mobile/shared/widgets/swipe_back_wrapper.dart';

// Mirrors the Figma "Add loads" screen.
class LoadFormScreen extends ConsumerStatefulWidget {
  const LoadFormScreen({super.key, this.loadId});
  final String? loadId;

  @override
  ConsumerState<LoadFormScreen> createState() => _LoadFormScreenState();
}

class _LoadFormScreenState extends ConsumerState<LoadFormScreen> {
  final _minTemp = TextEditingController();
  final _maxTemp = TextEditingController();
  final _price = TextEditingController();
  final _capacity = TextEditingController();
  final _weight = TextEditingController();
  final _comments = TextEditingController();

  LocationItem? _from;
  LocationItem? _to;
  String? _truckType;
  String? _cargoPart;
  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;
  DateTime? _deliveryDate;
  TimeOfDay? _deliveryTime;
  String _currency = 'USD';
  String? _paymentType;
  String _capacityUnit = 'm3';
  String _weightUnit = 'tons';
  String? _viewFor;
  String? _autoExpire;
  bool _submitting = false;

  bool get _isEdit => widget.loadId != null;

  static const _truckTypes = [
    'Tent / Shtora', 'Refrigerator', 'Isuzu NQR / NPR',
    'Trailer', "Container 20'", "Container 40'", 'Flatbed',
  ];

  @override
  void dispose() {
    _minTemp.dispose();
    _maxTemp.dispose();
    _price.dispose();
    _capacity.dispose();
    _weight.dispose();
    _comments.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime? d) => d == null
      ? ''
      : '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  String _fmtTime(TimeOfDay? t) => t == null
      ? ''
      : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickLocation({required bool isFrom}) async {
    final v = await showSelectLocationDrawer(
      context: context,
      title: (isFrom ? 'addLoad.pickupLoc' : 'addLoad.destLoc').tr(ref),
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
    final v = await showDsActionDrawer<String>(
      context: context,
      title: 'addLoad.truckType'.tr(ref),
      currentValue: _truckType,
      items: _truckTypes.map((t) => DsActionDrawerItem(value: t, label: t)).toList(),
    );
    if (v != null) setState(() => _truckType = v);
  }

  Future<void> _pickCargoPart() async {
    final v = await showDsActionDrawer<String>(
      context: context,
      title: 'addLoad.partOfCargo'.tr(ref),
      currentValue: _cargoPart,
      items: [
        DsActionDrawerItem(value: 'full', label: 'addLoad.cargo.full'.tr(ref)),
        DsActionDrawerItem(value: 'partial', label: 'addLoad.cargo.partial'.tr(ref)),
      ],
    );
    if (v != null) setState(() => _cargoPart = v);
  }

  Future<void> _pickPaymentType() async {
    final v = await showDsActionDrawer<String>(
      context: context,
      title: 'addLoad.paymentType'.tr(ref),
      currentValue: _paymentType,
      items: [
        DsActionDrawerItem(value: 'cash', label: 'addLoad.payment.cash'.tr(ref), leading: const Icon(Icons.payments_outlined)),
        DsActionDrawerItem(value: 'card', label: 'addLoad.payment.card'.tr(ref), leading: const Icon(Icons.credit_card_outlined)),
        DsActionDrawerItem(value: 'banking', label: 'addLoad.payment.banking'.tr(ref), leading: const Icon(Icons.account_balance_outlined)),
      ],
    );
    if (v != null) setState(() => _paymentType = v);
  }

  Future<void> _pickCurrency() async {
    final v = await showDsActionDrawer<String>(
      context: context,
      title: 'form.label.currency'.tr(ref),
      currentValue: _currency,
      items: const [
        DsActionDrawerItem(value: 'USD', label: 'USD'),
        DsActionDrawerItem(value: 'UZS', label: 'UZS'),
        DsActionDrawerItem(value: 'RUB', label: 'RUB'),
      ],
    );
    if (v != null) setState(() => _currency = v);
  }

  Future<void> _pickCapacityUnit() async {
    final v = await showDsActionDrawer<String>(
      context: context,
      title: 'addLoad.loadCapacity'.tr(ref),
      currentValue: _capacityUnit,
      items: const [
        DsActionDrawerItem(value: 'm3', label: 'm³'),
        DsActionDrawerItem(value: 'pallets', label: 'Pallets'),
      ],
    );
    if (v != null) setState(() => _capacityUnit = v);
  }

  Future<void> _pickWeightUnit() async {
    final v = await showDsActionDrawer<String>(
      context: context,
      title: 'addLoad.weight'.tr(ref),
      currentValue: _weightUnit,
      items: const [
        DsActionDrawerItem(value: 'tons', label: 'tons'),
        DsActionDrawerItem(value: 'kg', label: 'kg'),
      ],
    );
    if (v != null) setState(() => _weightUnit = v);
  }

  Future<void> _pickViewer() async {
    final v = await showDsActionDrawer<String>(
      context: context,
      title: 'addLoad.viewFor'.tr(ref),
      currentValue: _viewFor,
      items: [
        DsActionDrawerItem(value: 'all', label: 'addLoad.viewer.all'.tr(ref)),
        DsActionDrawerItem(value: 'shipper', label: 'addLoad.viewer.shipper'.tr(ref)),
        DsActionDrawerItem(value: 'broker', label: 'addLoad.viewer.broker'.tr(ref)),
        DsActionDrawerItem(value: 'carrier', label: 'addLoad.viewer.carrier'.tr(ref)),
      ],
    );
    if (v != null) setState(() => _viewFor = v);
  }

  Future<void> _pickExpire() async {
    final v = await showDsActionDrawer<String>(
      context: context,
      title: 'addLoad.autoExpire'.tr(ref),
      currentValue: _autoExpire,
      items: [
        DsActionDrawerItem(value: '6h', label: 'addLoad.expire.6h'.tr(ref)),
        DsActionDrawerItem(value: '24h', label: 'addLoad.expire.24h'.tr(ref)),
        DsActionDrawerItem(value: '3d', label: 'addLoad.expire.3d'.tr(ref)),
      ],
    );
    if (v != null) setState(() => _autoExpire = v);
  }

  Future<void> _pickDate({required bool isPickup}) async {
    final now = DateTime.now();
    final picked = await showCupertinoDateSheet(
      context,
      title: (isPickup ? 'addLoad.pickupDate' : 'addLoad.deliveryDate').tr(ref),
      initial: (isPickup ? _pickupDate : _deliveryDate) ?? now,
      minimum: now.subtract(const Duration(days: 1)),
      maximum: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isPickup) {
          _pickupDate = picked;
        } else {
          _deliveryDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime({required bool isPickup}) async {
    final picked = await showCupertinoTimeSheet(
      context,
      title: (isPickup ? 'addLoad.pickupTime' : 'addLoad.deliveryTime').tr(ref),
      initial: (isPickup ? _pickupTime : _deliveryTime) ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isPickup) {
          _pickupTime = picked;
        } else {
          _deliveryTime = picked;
        }
      });
    }
  }

  bool get _formValid {
    return _from != null &&
        _to != null &&
        _truckType != null &&
        _cargoPart != null &&
        _pickupDate != null &&
        _pickupTime != null &&
        _deliveryDate != null &&
        _deliveryTime != null &&
        _paymentType != null &&
        (double.tryParse(_capacity.text.trim()) ?? 0) > 0 &&
        (double.tryParse(_weight.text.trim()) ?? 0) > 0;
  }

  Future<void> _submit() async {
    if (!_formValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('common.required'.tr(ref))),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(loadsControllerProvider.notifier).saveLoad(
            loadId: widget.loadId,
            fromAddress: '${_from!.country} · ${_from!.title}',
            toAddress: '${_to!.country} · ${_to!.title}',
            comment: _comments.text.trim(),
          );
      if (!mounted) return;
      await showDsSuccessModal(
        context,
        title: 'success.title'.tr(ref),
        message: 'success.addLoadMessage'.tr(ref),
        actionLabel: 'success.goToMyLoads'.tr(ref),
        onAction: () => context.go('/my-loads'),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.space;
    final t = context.types;

    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: c.background,
        body: Column(
          children: [
            // Top bar — LoadMe logo (left), X close (right). Per Figma `Add load_date`.
            Container(
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
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
                      const Spacer(),
                      InkResponse(
                        onTap: () => context.canPop() ? context.pop() : context.go('/my-loads'),
                        radius: 22,
                        child: Icon(Icons.close_rounded, color: c.textPrimary, size: 24),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(s.lg, s.lg, s.lg, s.xl),
                children: [
                  _SectionTitle('Locations'),
                  SizedBox(height: s.sm),
                  AddLoadLabel(text: 'addLoad.pickupLoc'.tr(ref), required: true),
                  AddLoadSelectTile(
                    hintText: 'addLoad.choose'.tr(ref),
                    value: _from == null ? null : '${_from!.country} · ${_from!.title}',
                    icon: Icons.location_on_outlined,
                    onTap: () => _pickLocation(isFrom: true),
                  ),
                  SizedBox(height: s.md),

                  AddLoadLabel(text: 'addLoad.destLoc'.tr(ref), required: true),
                  AddLoadSelectTile(
                    hintText: 'addLoad.choose'.tr(ref),
                    value: _to == null ? null : '${_to!.country} · ${_to!.title}',
                    icon: Icons.location_on_outlined,
                    onTap: () => _pickLocation(isFrom: false),
                  ),
                  SizedBox(height: s.xl),

                  _SectionTitle('Cargo'),
                  SizedBox(height: s.sm),
                  AddLoadLabel(text: 'addLoad.truckType'.tr(ref), required: true),
                  AddLoadSelectTile(
                    hintText: 'addLoad.choose'.tr(ref),
                    value: _truckType,
                    onTap: _pickTruckType,
                  ),
                  SizedBox(height: s.md),

                  AddLoadLabel(text: 'addLoad.partOfCargo'.tr(ref), required: true),
                  AddLoadSelectTile(
                    hintText: 'addLoad.choose'.tr(ref),
                    value: _cargoPart == null
                        ? null
                        : (_cargoPart == 'full' ? 'addLoad.cargo.full' : 'addLoad.cargo.partial').tr(ref),
                    onTap: _pickCargoPart,
                  ),
                  SizedBox(height: s.md),

                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      AddLoadLabel(text: 'addLoad.minTemp'.tr(ref), required: true),
                      AddLoadField(controller: _minTemp, hintText: 'addLoad.enter'.tr(ref), keyboardType: TextInputType.number),
                    ])),
                    SizedBox(width: s.md),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      AddLoadLabel(text: 'addLoad.maxTemp'.tr(ref), required: true),
                      AddLoadField(controller: _maxTemp, hintText: 'addLoad.enter'.tr(ref), keyboardType: TextInputType.number),
                    ])),
                  ]),
                  SizedBox(height: s.xl),

                  _SectionTitle('Dates'),
                  SizedBox(height: s.sm),
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      AddLoadLabel(text: 'addLoad.pickupDate'.tr(ref), required: true),
                      AddLoadSelectTile(hintText: 'addLoad.choose'.tr(ref), value: _pickupDate == null ? null : _fmtDate(_pickupDate), icon: Icons.calendar_today_outlined, onTap: () => _pickDate(isPickup: true)),
                    ])),
                    SizedBox(width: s.md),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      AddLoadLabel(text: 'addLoad.pickupTime'.tr(ref), required: true),
                      AddLoadSelectTile(hintText: 'addLoad.choose'.tr(ref), value: _pickupTime == null ? null : _fmtTime(_pickupTime), icon: Icons.access_time_rounded, onTap: () => _pickTime(isPickup: true)),
                    ])),
                  ]),
                  SizedBox(height: s.md),

                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      AddLoadLabel(text: 'addLoad.deliveryDate'.tr(ref), required: true),
                      AddLoadSelectTile(hintText: 'addLoad.choose'.tr(ref), value: _deliveryDate == null ? null : _fmtDate(_deliveryDate), icon: Icons.calendar_today_outlined, onTap: () => _pickDate(isPickup: false)),
                    ])),
                    SizedBox(width: s.md),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      AddLoadLabel(text: 'addLoad.deliveryTime'.tr(ref), required: true),
                      AddLoadSelectTile(hintText: 'addLoad.choose'.tr(ref), value: _deliveryTime == null ? null : _fmtTime(_deliveryTime), icon: Icons.access_time_rounded, onTap: () => _pickTime(isPickup: false)),
                    ])),
                  ]),
                  SizedBox(height: s.xl),

                  _SectionTitle('Payment'),
                  SizedBox(height: s.sm),
                  AddLoadLabel(text: 'addLoad.price'.tr(ref)),
                  AddLoadInputWithUnit(controller: _price, hintText: 'addLoad.enter'.tr(ref), unit: _currency, onUnitTap: _pickCurrency),
                  SizedBox(height: s.md),

                  AddLoadLabel(text: 'addLoad.paymentType'.tr(ref), required: true),
                  AddLoadSelectTile(
                    hintText: 'addLoad.choose'.tr(ref),
                    value: _paymentType == null ? null : 'addLoad.payment.${_paymentType!}'.tr(ref),
                    onTap: _pickPaymentType,
                  ),
                  SizedBox(height: s.md),

                  SizedBox(height: s.xl),
                  _SectionTitle('Cargo size'),
                  SizedBox(height: s.sm),
                  AddLoadLabel(text: 'addLoad.loadCapacity'.tr(ref), required: true),
                  AddLoadInputWithUnit(controller: _capacity, hintText: 'addLoad.enter'.tr(ref), unit: _capacityUnit == 'm3' ? 'm³' : _capacityUnit, onUnitTap: _pickCapacityUnit),
                  SizedBox(height: s.md),

                  AddLoadLabel(text: 'addLoad.weight'.tr(ref), required: true),
                  AddLoadInputWithUnit(controller: _weight, hintText: 'addLoad.enter'.tr(ref), unit: _weightUnit, onUnitTap: _pickWeightUnit),
                  SizedBox(height: s.xl),

                  _SectionTitle('Visibility'),
                  SizedBox(height: s.sm),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Text('addLoad.viewFor'.tr(ref), style: t.bodyMedium.copyWith(color: c.textPrimary)),
                      const SizedBox(width: 4),
                      Icon(Icons.info_outline, color: c.primary, size: 16),
                    ]),
                  ),
                  AddLoadSelectTile(
                    hintText: 'addLoad.choose'.tr(ref),
                    value: _viewFor == null ? null : 'addLoad.viewer.${_viewFor!}'.tr(ref),
                    onTap: _pickViewer,
                  ),
                  SizedBox(height: s.md),

                  AddLoadLabel(text: 'addLoad.autoExpire'.tr(ref), required: true),
                  AddLoadSelectTile(
                    hintText: 'addLoad.choose'.tr(ref),
                    value: _autoExpire == null ? null : 'addLoad.expire.${_autoExpire!}'.tr(ref),
                    onTap: _pickExpire,
                  ),
                  SizedBox(height: s.md),

                  AddLoadLabel(text: 'addLoad.comments'.tr(ref)),
                  Container(
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: c.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: TextField(
                      controller: _comments,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'addLoad.enter'.tr(ref),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Sticky Create button
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: DsButton(
                  label: (_isEdit ? 'common.save' : 'addLoad.create').tr(ref),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: context.types.h3.copyWith(color: context.colors.textPrimary));
  }
}
