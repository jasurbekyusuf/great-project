import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_controller.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';
import 'package:loadme_mobile/shared/design_system/ds_input.dart';
import 'package:loadme_mobile/shared/widgets/app_scaffold.dart';

class LoadFormScreen extends ConsumerStatefulWidget {
  const LoadFormScreen({super.key, this.loadId});

  final String? loadId;

  @override
  ConsumerState<LoadFormScreen> createState() => _LoadFormScreenState();
}

class _LoadFormScreenState extends ConsumerState<LoadFormScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.loadId != null;

    return AppScaffold(
      title: isEdit ? 'Edit Load' : 'Add Load',
      body: Padding(
        padding: EdgeInsets.all(context.space.lg),
        child: Column(
          children: [
            DsInput(controller: _fromController, label: 'From address'),
            SizedBox(height: context.space.md),
            DsInput(controller: _toController, label: 'To address'),
            SizedBox(height: context.space.md),
            DsInput(controller: _commentController, label: 'Comment'),
            SizedBox(height: context.space.lg),
            DsButton(
              label: isEdit ? 'Save changes' : 'Create load',
              onPressed: () async {
                await ref.read(loadsControllerProvider.notifier).saveLoad(
                      loadId: widget.loadId,
                      fromAddress: _fromController.text.trim(),
                      toAddress: _toController.text.trim(),
                      comment: _commentController.text.trim(),
                    );
                if (context.mounted) context.go('/loads');
              },
            ),
          ],
        ),
      ),
    );
  }
}
