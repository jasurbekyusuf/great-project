import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';
import 'package:loadme_mobile/shared/design_system/ds_card.dart';
import 'package:loadme_mobile/shared/widgets/app_scaffold.dart';

// Mirrors `client_frontend_web-master/src/modules/DefaultCommission/index.jsx`.
// TODO: wire commission update mutation.
class DefaultCommissionScreen extends ConsumerStatefulWidget {
  const DefaultCommissionScreen({super.key});

  @override
  ConsumerState<DefaultCommissionScreen> createState() => _DefaultCommissionScreenState();
}

class _DefaultCommissionScreenState extends ConsumerState<DefaultCommissionScreen> {
  final _percent = TextEditingController(text: '5');
  String _type = 'percent';

  @override
  void dispose() {
    _percent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.space;
    final t = context.types;
    final c = context.colors;

    return AppScaffold(
      title: 'profile.commission'.tr(ref),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: s.lg),
        children: [
          DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('commission.hint'.tr(ref), style: t.caption),
                SizedBox(height: s.lg),
                Text('commission.type'.tr(ref), style: t.caption.copyWith(color: c.textSecondary)),
                SizedBox(height: s.sm),
                RadioGroup<String>(
                  groupValue: _type,
                  onChanged: (v) => setState(() => _type = v!),
                  child: Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          value: 'percent',
                          title: Text('commission.percent'.tr(ref)),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          value: 'fixed',
                          title: Text('commission.fixed'.tr(ref)),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: s.md),
                Text(_type == 'percent' ? '${'commission.percent'.tr(ref)} (%)' : 'commission.amount'.tr(ref), style: t.caption),
                SizedBox(height: s.sm),
                TextField(
                  controller: _percent,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: '5'),
                ),
              ],
            ),
          ),
          SizedBox(height: s.xl),
          DsButton(label: 'common.save'.tr(ref), onPressed: () {}),
        ],
      ),
    );
  }
}
