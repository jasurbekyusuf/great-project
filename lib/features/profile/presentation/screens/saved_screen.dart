import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/shared/design_system/ds_card.dart';
import 'package:loadme_mobile/shared/widgets/app_scaffold.dart';
import 'package:loadme_mobile/shared/widgets/mobile_segmented_tab.dart';

// Mirrors `client_frontend_web-master/src/modules/SavedPage/index.jsx`.
// TODO: wire to /saved-loads and /saved-trucks endpoints.
class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.space;
    final t = context.types;

    return AppScaffold(
      title: 'profile.saved'.tr(ref),
      padded: false,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(s.lg, s.md, s.lg, s.md),
            child: MobileSegmentedTab(
              items: ['saved.tab.loads'.tr(ref), 'saved.tab.trucks'.tr(ref)],
              selectedIndex: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(s.lg, 0, s.lg, s.xl),
              itemCount: 6,
              separatorBuilder: (_, __) => SizedBox(height: s.md),
              itemBuilder: (_, i) => DsCard(
                onTap: () {},
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ташкент → Самарканд', style: t.bodyLgMedium),
                    SizedBox(height: s.xs),
                    Text('Тент · 20 т · 2 500 000 UZS', style: t.caption),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
