import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/shared/design_system/ds_action_drawer.dart';
import 'package:loadme_mobile/shared/widgets/image_uploader.dart';
import 'package:loadme_mobile/shared/widgets/mobile_form_components.dart';
import 'package:loadme_mobile/shared/widgets/mobile_page_head.dart';
import 'package:loadme_mobile/shared/widgets/select_location_drawer.dart';
import 'package:loadme_mobile/shared/widgets/swipe_back_wrapper.dart';

// Mirrors web `AddPostTruck`. Driver offers a free truck for a route.
class PostTruckFormScreen extends ConsumerStatefulWidget {
  const PostTruckFormScreen({super.key, this.postTruckId});
  final String? postTruckId;

  @override
  ConsumerState<PostTruckFormScreen> createState() => _PostTruckFormScreenState();
}

class _PostTruckFormScreenState extends ConsumerState<PostTruckFormScreen> {
  final _priceController = TextEditingController();
  final _capacityController = TextEditingController();
  final _weightController = TextEditingController();
  final _commentController = TextEditingController();

  LocationItem? _from;
  LocationItem? _to;
  DateTime? _pickupDate;
  DateTime? _deliveryDate;
  String? _truckType;
  String _currency = 'USD';
  String _visibleFor = 'Hammaga';
  String _expireTime = '24 soat';
  List<String> _photoUrls = [];
  bool _submitting = false;

  bool get _isEdit => widget.postTruckId != null;

  static const _truckTypes = [
    'Tent / Shtora', 'Refrigerator', 'Isuzu NQR / NPR', 'Trailer',
    'Container 20\'', 'Container 40\'', 'Flatbed',
  ];

  @override
  void dispose() {
    _priceController.dispose();
    _capacityController.dispose();
    _weightController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime? d) => d == null
      ? ''
      : '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  Future<void> _pickFrom() async {
    final v = await showSelectLocationDrawer(context: context, title: 'Qayerdan', currentId: _from?.id);
    if (v != null) setState(() => _from = v);
  }

  Future<void> _pickTo() async {
    final v = await showSelectLocationDrawer(context: context, title: 'Qayerga', currentId: _to?.id);
    if (v != null) setState(() => _to = v);
  }

  Future<void> _pickDate({required bool isPickup}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      initialDate: (isPickup ? _pickupDate : _deliveryDate) ?? now,
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

  Future<void> _pickTruckType() async {
    final v = await showDsActionDrawer<String>(
      context: context,
      title: 'Kuzov turi',
      currentValue: _truckType,
      items: _truckTypes.map((t) => DsActionDrawerItem(value: t, label: t)).toList(),
    );
    if (v != null) setState(() => _truckType = v);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.space;
    final t = Theme.of(context).textTheme;
    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: Column(
          children: [
            MobilePageHead(
              title: (_isEdit ? 'form.editPostTruckTitle' : 'form.addPostTruckTitle').tr(ref),
              onBack: () => context.canPop() ? context.pop() : context.go('/my-trucks'),
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(s.lg, s.lg, s.lg, s.xl),
                children: [
                  MobileFormSection(title: 'Yo\'nalish', children: [
                    MobileSelectTile(
                      label: 'Qayerdan',
                      value: _from == null ? 'Tanlash' : '${_from!.country} · ${_from!.title}',
                      icon: Icons.trip_origin_rounded,
                      onTap: _pickFrom,
                    ),
                    SizedBox(height: s.md),
                    MobileSelectTile(
                      label: 'Qayerga',
                      value: _to == null ? 'Tanlash' : '${_to!.country} · ${_to!.title}',
                      icon: Icons.place_rounded,
                      onTap: _pickTo,
                    ),
                    SizedBox(height: s.md),
                    Row(children: [
                      Expanded(
                        child: MobileSelectTile(
                          label: 'Yuklash sanasi',
                          value: _pickupDate == null ? 'Tanlash' : _fmtDate(_pickupDate),
                          icon: Icons.calendar_today_rounded,
                          onTap: () => _pickDate(isPickup: true),
                        ),
                      ),
                      SizedBox(width: s.md),
                      Expanded(
                        child: MobileSelectTile(
                          label: 'Yetkazish sanasi',
                          value: _deliveryDate == null ? 'Tanlash' : _fmtDate(_deliveryDate),
                          icon: Icons.calendar_month_rounded,
                          onTap: () => _pickDate(isPickup: false),
                        ),
                      ),
                    ]),
                  ]),
                  SizedBox(height: s.md),
                  MobileFormSection(title: 'Mashina', children: [
                    MobileSelectTile(
                      label: 'Kuzov turi',
                      value: _truckType ?? 'Tanlash',
                      icon: Icons.local_shipping_outlined,
                      onTap: _pickTruckType,
                    ),
                    SizedBox(height: s.md),
                    Row(children: [
                      Expanded(child: MobileFormField(label: 'Sig\'im', controller: _capacityController, keyboardType: TextInputType.number, suffixText: 'm³', required: true)),
                      SizedBox(width: s.md),
                      Expanded(child: MobileFormField(label: 'Yuk ko\'tarish', controller: _weightController, keyboardType: TextInputType.number, suffixText: 't', required: true)),
                    ]),
                  ]),
                  SizedBox(height: s.md),
                  MobileFormSection(title: 'Narx', children: [
                    Row(children: [
                      Expanded(child: MobileFormField(label: 'Narx', controller: _priceController, keyboardType: TextInputType.number, suffixText: _currency)),
                      SizedBox(width: s.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Valyuta', style: t.titleMedium),
                            SizedBox(height: s.sm),
                            MobileChipGroup(items: const ['UZS', 'USD'], selected: _currency, onChanged: (v) => setState(() => _currency = v)),
                          ],
                        ),
                      ),
                    ]),
                  ]),
                  SizedBox(height: s.md),
                  MobileFormSection(title: 'Ko\'rinish va izoh', children: [
                    Text('Kimlarga ko\'rinsin', style: t.titleMedium),
                    SizedBox(height: s.sm),
                    MobileChipGroup(items: const ['Hammaga', 'Shipper', 'Broker', 'Carrier'], selected: _visibleFor, onChanged: (v) => setState(() => _visibleFor = v)),
                    SizedBox(height: s.md),
                    Text('E\'lon muddati', style: t.titleMedium),
                    SizedBox(height: s.sm),
                    MobileChipGroup(items: const ['6 soat', '24 soat', '3 kun'], selected: _expireTime, onChanged: (v) => setState(() => _expireTime = v)),
                    SizedBox(height: s.md),
                    Text('Rasm qo\'shing', style: t.titleMedium),
                    SizedBox(height: s.sm),
                    ImageUploader(
                      urls: _photoUrls,
                      maxCount: 5,
                      onAdd: () => setState(() => _photoUrls = [..._photoUrls, 'https://picsum.photos/seed/postk${_photoUrls.length}/200/200']),
                      onRemove: (i) => setState(() => _photoUrls = [..._photoUrls]..removeAt(i)),
                    ),
                    SizedBox(height: s.md),
                    MobileFormField(label: 'Izoh', controller: _commentController, maxLines: 4),
                  ]),
                ],
              ),
            ),
            MobileBottomSubmitBar(
              label: (_isEdit ? 'form.submit.editTruck' : 'form.submit.publish').tr(ref),
              isLoading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final errors = <String>[];
    if (_from == null) errors.add('Qayerdan: tanlash kerak');
    if (_to == null) errors.add('Qayerga: tanlash kerak');
    if (_truckType == null) errors.add('Kuzov turi: tanlash kerak');
    final w = double.tryParse(_weightController.text.trim());
    if (w == null || w <= 0) errors.add('Yuk ko\'tarish: musbat son');
    final c = double.tryParse(_capacityController.text.trim());
    if (c == null || c <= 0) errors.add('Sig\'im: musbat son');
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errors.join('\n')), duration: const Duration(seconds: 4)));
      return;
    }
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _submitting = false);
    context.go('/my-trucks');
  }
}
