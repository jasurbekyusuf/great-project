import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/features/feedback/presentation/feedback_providers.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';

const _star = Color(0xFFF79009); // filled rating star (amber)

/// Rounded white bottom sheet shell shared by the rate / report flows.
Future<bool?> _showSheet(BuildContext context, Widget child) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => Padding(
      // Lift above the keyboard when the note field is focused.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: child,
    ),
  );
}

Widget _handle() => Center(
      child: Container(
        width: 42,
        height: 5,
        margin: const EdgeInsets.only(top: 12, bottom: 16),
        decoration: BoxDecoration(
          color: FigmaPalette.divider,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );

// ---------------------------------------------------------------------------
// Rating sheet — stars (1–5) + optional note → POST /feedback/ratings/
// ---------------------------------------------------------------------------

/// Opens the "Baholash" sheet for [toUser]. [truckRoute] scopes the rating to a
/// route (transport detail); a load owner is rated without it. Returns true
/// when a rating was submitted.
Future<bool?> showRatingSheet(
  BuildContext context, {
  required String toUser,
  String? truckRoute,
}) {
  return _showSheet(
    context,
    _RatingSheet(toUser: toUser, truckRoute: truckRoute),
  );
}

class _RatingSheet extends ConsumerStatefulWidget {
  const _RatingSheet({required this.toUser, this.truckRoute});
  final String toUser;
  final String? truckRoute;

  @override
  ConsumerState<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends ConsumerState<_RatingSheet> {
  final _notes = TextEditingController();
  int _rate = 0;
  bool _busy = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rate == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('feedback.rate.required'.tr(ref))),
      );
      return;
    }
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      await ref.read(feedbackDataSourceProvider).submitRating(
            toUser: widget.toUser,
            truckRoute: widget.truckRoute,
            rate: _rate,
            notes: _notes.text,
          );
      messenger.showSnackBar(
        SnackBar(content: Text('feedback.rate.success'.tr(ref))),
      );
      nav.pop(true);
    } catch (_) {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text('feedback.error'.tr(ref))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _handle(),
            Text(
              'transport.rate'.tr(ref),
              style: const TextStyle(
                fontSize: 18,
                height: 24 / 18,
                fontWeight: FontWeight.w600,
                color: FigmaPalette.inkStrong,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'feedback.rate.subtitle'.tr(ref),
              style: const TextStyle(
                fontSize: 13,
                height: 18 / 13,
                fontWeight: FontWeight.w500,
                color: FigmaPalette.gray700,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      onPressed: _busy ? null : () => setState(() => _rate = i),
                      icon: Icon(
                        i <= _rate ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 40,
                        color: i <= _rate ? _star : FigmaPalette.divider,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _NoteField(
              controller: _notes,
              hint: 'feedback.rate.notes'.tr(ref),
              enabled: !_busy,
            ),
            const SizedBox(height: 20),
            DsButton(
              label: 'feedback.submit'.tr(ref),
              loading: _busy,
              onPressed: _busy ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Complaint sheet — reason picker + optional note → POST /feedback/complaints/
// ---------------------------------------------------------------------------

/// Opens the "Shikoyat qilish" sheet for [toUser] about the [load] OR [route]
/// it was opened from. Returns true when a complaint was submitted.
Future<bool?> showComplaintSheet(
  BuildContext context, {
  required String toUser,
  String? load,
  String? route,
}) {
  return _showSheet(
    context,
    _ComplaintSheet(toUser: toUser, load: load, route: route),
  );
}

class _ComplaintSheet extends ConsumerStatefulWidget {
  const _ComplaintSheet({required this.toUser, this.load, this.route});
  final String toUser;
  final String? load;
  final String? route;

  @override
  ConsumerState<_ComplaintSheet> createState() => _ComplaintSheetState();
}

class _ComplaintSheetState extends ConsumerState<_ComplaintSheet> {
  final _note = TextEditingController();
  String? _typeId;
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_typeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('feedback.report.required'.tr(ref))),
      );
      return;
    }
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      await ref.read(feedbackDataSourceProvider).submitComplaint(
            toUser: widget.toUser,
            complaintType: _typeId!,
            load: widget.load,
            route: widget.route,
            note: _note.text,
          );
      messenger.showSnackBar(
        SnackBar(content: Text('feedback.report.success'.tr(ref))),
      );
      nav.pop(true);
    } catch (_) {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text('feedback.error'.tr(ref))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = ref.watch(complaintTypesProvider);
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _handle(),
              Text(
                'transport.report'.tr(ref),
                style: const TextStyle(
                  fontSize: 18,
                  height: 24 / 18,
                  fontWeight: FontWeight.w600,
                  color: FigmaPalette.inkStrong,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'feedback.report.subtitle'.tr(ref),
                style: const TextStyle(
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w500,
                  color: FigmaPalette.gray700,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: types.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: FigmaPalette.primary),
                    ),
                  ),
                  error: (_, __) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('feedback.error'.tr(ref))),
                  ),
                  data: (items) => ListView(
                    shrinkWrap: true,
                    children: [
                      for (final t in items)
                        _ReasonTile(
                          label: t.name,
                          selected: _typeId == t.id,
                          onTap: _busy
                              ? null
                              : () => setState(() => _typeId = t.id),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _NoteField(
                controller: _note,
                hint: 'feedback.report.note'.tr(ref),
                enabled: !_busy,
              ),
              const SizedBox(height: 20),
              DsButton(
                label: 'feedback.submit'.tr(ref),
                variant: DsButtonVariant.report,
                loading: _busy,
                onPressed: _busy ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 22,
              color: selected ? FigmaPalette.primary : FigmaPalette.divider,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w500,
                  color: selected ? FigmaPalette.inkStrong : FigmaPalette.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Multiline note input shared by both sheets — a neutral filled box matching
/// the chip surface used elsewhere on the detail screens.
class _NoteField extends StatelessWidget {
  const _NoteField({
    required this.controller,
    required this.hint,
    this.enabled = true,
  });
  final TextEditingController controller;
  final String hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      minLines: 2,
      maxLines: 4,
      style: const TextStyle(fontSize: 14, color: FigmaPalette.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: FigmaPalette.label),
        filled: true,
        fillColor: FigmaPalette.chipBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FigmaPalette.primary),
        ),
      ),
    );
  }
}
