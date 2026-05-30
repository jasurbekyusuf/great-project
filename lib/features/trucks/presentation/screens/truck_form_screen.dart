import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/shared/design_system/ds_action_drawer.dart';
import 'package:loadme_mobile/shared/widgets/image_uploader.dart';
import 'package:loadme_mobile/shared/widgets/mobile_form_components.dart';
import 'package:loadme_mobile/shared/widgets/mobile_page_head.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/shared/widgets/swipe_back_wrapper.dart';

class TruckFormScreen extends ConsumerStatefulWidget {
  const TruckFormScreen({super.key, this.truckId});

  final String? truckId;

  @override
  ConsumerState<TruckFormScreen> createState() => _TruckFormScreenState();
}

class _TruckFormScreenState extends ConsumerState<TruckFormScreen> {
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();
  final _trailerController = TextEditingController();
  final _capacityController = TextEditingController();
  final _weightController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController(text: '+998');
  final _commentController = TextEditingController();

  String? _truckType;
  var _status = 'Faol';
  var _submitting = false;
  List<String> _photoUrls = [];

  static const _truckTypes = [
    'Tent / Shtora', 'Refrigerator', 'Isuzu NQR / NPR', 'Trailer',
    'Container 20\'', 'Container 40\'', 'Flatbed',
  ];

  bool get _isEdit => widget.truckId != null;

  @override
  void dispose() {
    _modelController.dispose();
    _plateController.dispose();
    _trailerController.dispose();
    _capacityController.dispose();
    _weightController.dispose();
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _commentController.dispose();
    super.dispose();
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
    return SwipeBackWrapper(
      child: Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            MobilePageHead(
              title: (_isEdit ? 'form.editTruckTitle' : 'form.addTruckTitle').tr(ref),
              onBack: () =>
                  context.canPop() ? context.pop() : context.go('/my-trucks'),
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(context.space.lg, context.space.lg,
                    context.space.lg, context.space.xl),
                children: [
                  MobileFormSection(
                    title: 'Transport',
                    children: [
                      MobileFormField(label: 'Model', controller: _modelController, required: true),
                      const _FormGap(),
                      MobileFormField(label: 'Davlat raqami', controller: _plateController, required: true),
                      const _FormGap(),
                      MobileFormField(label: 'Tirkama raqami', controller: _trailerController),
                      const _FormGap(),
                      MobileSelectTile(
                        label: 'Kuzov turi',
                        value: _truckType ?? 'Tanlash',
                        icon: Icons.local_shipping_outlined,
                        onTap: _pickTruckType,
                      ),
                    ],
                  ),
                  const _SectionGap(),
                  MobileFormSection(
                    title: 'Sig\'im',
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: MobileFormField(
                              label: 'Kubatura',
                              controller: _capacityController,
                              keyboardType: TextInputType.number,
                              suffixText: 'm3',
                              required: true,
                            ),
                          ),
                          SizedBox(width: context.space.md),
                          Expanded(
                            child: MobileFormField(
                              label: 'Yuk ko\'tarish',
                              controller: _weightController,
                              keyboardType: TextInputType.number,
                              suffixText: 't',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const _SectionGap(),
                  MobileFormSection(
                    title: 'Haydovchi',
                    children: [
                      MobileFormField(
                          label: 'Ism', controller: _driverNameController),
                      const _FormGap(),
                      MobileFormField(
                        label: 'Telefon',
                        controller: _driverPhoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      const _FormGap(),
                      Text('Holati',
                          style: Theme.of(context).textTheme.titleMedium),
                      SizedBox(height: context.space.sm),
                      MobileChipGroup(
                        items: const ['Faol', 'Band', 'Arxiv'],
                        selected: _status,
                        onChanged: (value) => setState(() => _status = value),
                      ),
                    ],
                  ),
                  const _SectionGap(),
                  MobileFormSection(
                    title: 'Hujjatlar',
                    children: [
                      Text('Rasm qo\'shing', style: Theme.of(context).textTheme.titleMedium),
                      SizedBox(height: context.space.sm),
                      ImageUploader(
                        urls: _photoUrls,
                        maxCount: 5,
                        onAdd: () => setState(() => _photoUrls = [..._photoUrls, 'https://picsum.photos/seed/truck${_photoUrls.length}/200/200']),
                        onRemove: (i) => setState(() => _photoUrls = [..._photoUrls]..removeAt(i)),
                      ),
                      const _FormGap(),
                      MobileFormField(label: 'Izoh', controller: _commentController, maxLines: 4),
                    ],
                  ),
                ],
              ),
            ),
            MobileBottomSubmitBar(
              label: (_isEdit ? 'form.submit.editTruck' : 'form.submit.createTruck').tr(ref),
              isLoading: _submitting,
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
    if (_plateController.text.trim().isEmpty) errors.add('Davlat raqami: kiritish kerak');
    if (_truckType == null) errors.add('Kuzov turi: tanlash kerak');
    final w = double.tryParse(_weightController.text.trim());
    if (w == null || w <= 0) errors.add('Yuk ko\'tarish: musbat son bo\'lishi kerak');
    final c = double.tryParse(_capacityController.text.trim());
    if (c == null || c <= 0) errors.add('Kubatura: musbat son bo\'lishi kerak');

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
    context.go('/my-trucks');
  }
}

class _SectionGap extends StatelessWidget {
  const _SectionGap();

  @override
  Widget build(BuildContext context) => SizedBox(height: context.space.md);
}

class _FormGap extends StatelessWidget {
  const _FormGap();

  @override
  Widget build(BuildContext context) => SizedBox(height: context.space.md);
}
