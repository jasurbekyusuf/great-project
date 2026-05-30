import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';
import 'package:loadme_mobile/shared/design_system/ds_card.dart';
import 'package:loadme_mobile/shared/widgets/app_scaffold.dart';
import 'package:loadme_mobile/shared/widgets/mobile_list_row.dart';

// Mirrors `client_frontend_web-master/src/modules/SupportFeedback/index.jsx`.
class SupportFeedbackScreen extends ConsumerStatefulWidget {
  const SupportFeedbackScreen({super.key});

  @override
  ConsumerState<SupportFeedbackScreen> createState() => _SupportFeedbackScreenState();
}

class _SupportFeedbackScreenState extends ConsumerState<SupportFeedbackScreen> {
  final _message = TextEditingController();

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.space;
    final t = context.types;

    return AppScaffold(
      title: 'profile.support'.tr(ref),
      padded: false,
      body: ListView(
        padding: EdgeInsets.fromLTRB(s.lg, s.lg, s.lg, s.xl),
        children: [
          MobileListGroup(children: [
            MobileListRow(
              leadingIcon: Icons.telegram_rounded,
              title: 'support.telegram'.tr(ref),
              subtitle: '@loadme_support',
              onTap: () {},
            ),
            MobileListRow(
              leadingIcon: Icons.phone_outlined,
              title: 'support.call'.tr(ref),
              subtitle: '+998 78 555 11 11',
              onTap: () {},
            ),
            MobileListRow(
              leadingIcon: Icons.mail_outline,
              title: 'support.email'.tr(ref),
              subtitle: 'support@loadme.uz',
              onTap: () {},
            ),
          ]),
          SizedBox(height: s.xl),
          Text('support.leaveMessage'.tr(ref), style: t.h3),
          SizedBox(height: s.md),
          DsCard(
            child: TextField(
              controller: _message,
              minLines: 5,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'support.placeholder'.tr(ref),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          SizedBox(height: s.lg),
          DsButton(label: 'common.send'.tr(ref), onPressed: () {}),
        ],
      ),
    );
  }
}
