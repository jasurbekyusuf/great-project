import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_controller.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';
import 'package:loadme_mobile/shared/design_system/ds_input.dart';
import 'package:loadme_mobile/shared/widgets/app_scaffold.dart';

class LoadsFiltersScreen extends ConsumerStatefulWidget {
  const LoadsFiltersScreen({super.key});

  @override
  ConsumerState<LoadsFiltersScreen> createState() => _LoadsFiltersScreenState();
}

class _LoadsFiltersScreenState extends ConsumerState<LoadsFiltersScreen> {
  final _queryController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Loads Filters',
      body: Padding(
        padding: EdgeInsets.all(context.space.lg),
        child: Column(
          children: [
            DsInput(controller: _queryController, label: 'From / To address search'),
            SizedBox(height: context.space.lg),
            DsButton(
              label: 'Apply',
              onPressed: () {
                ref.read(loadsControllerProvider.notifier).applyQuery(_queryController.text);
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
