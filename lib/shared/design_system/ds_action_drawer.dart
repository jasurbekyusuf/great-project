import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';

// Mirrors web `ActionDrawer` (src/components/drawers/ActionDrawer.jsx) `list` mode.
// Bottom sheet with a title, a list of selectable items, and a radio indicator.
class DsActionDrawerItem<T> {
  const DsActionDrawerItem({required this.value, required this.label, this.leading, this.iconAsset});
  final T value;
  final String label;
  final Widget? leading;
  final String? iconAsset;
}

Future<T?> showDsActionDrawer<T>({
  required BuildContext context,
  required String title,
  required List<DsActionDrawerItem<T>> items,
  T? currentValue,
  bool showConfirm = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    // Present above the StatefulShell so the scrim + sheet cover the bottom
    // nav bar (Figma: the open sheet overlays the navbar).
    useRootNavigator: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (ctx) => _DsActionDrawer<T>(
      title: title,
      items: items,
      currentValue: currentValue,
      showConfirm: showConfirm,
    ),
  );
}

class _DsActionDrawer<T> extends ConsumerStatefulWidget {
  const _DsActionDrawer({
    required this.title,
    required this.items,
    required this.currentValue,
    required this.showConfirm,
  });

  final String title;
  final List<DsActionDrawerItem<T>> items;
  final T? currentValue;
  final bool showConfirm;

  @override
  ConsumerState<_DsActionDrawer<T>> createState() =>
      _DsActionDrawerState<T>();
}

class _DsActionDrawerState<T> extends ConsumerState<_DsActionDrawer<T>> {
  late T? _selected = widget.currentValue;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.types;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: c.gray300, borderRadius: BorderRadius.circular(999)),
              ),
            ),
            if (widget.title.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(widget.title, style: t.h3),
              ),
              const SizedBox(height: 4),
            ],
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: widget.items.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: c.borderSubtle),
                itemBuilder: (_, i) {
                  final item = widget.items[i];
                  final active = item.value == _selected;
                  return InkWell(
                    onTap: () {
                      if (widget.showConfirm) {
                        setState(() => _selected = item.value);
                      } else {
                        Navigator.pop(context, item.value);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                      child: Row(
                        children: [
                          if (item.leading != null) ...[item.leading!, const SizedBox(width: 12)],
                          if (item.iconAsset != null) ...[
                            Image.asset(item.iconAsset!, width: 22, height: 22),
                            const SizedBox(width: 12),
                          ],
                          Expanded(child: Text(item.label, style: t.bodyLgMedium)),
                          _RadioDot(active: active, color: c.primary, border: c.gray300),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.showConfirm) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('common.cancel'.tr(ref)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _selected == null ? null : () => Navigator.pop(context, _selected),
                      child: Text('common.confirm'.tr(ref)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.active, required this.color, required this.border});
  final bool active;
  final Color color;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: active ? color : border, width: 1),
      ),
      child: active
          ? Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            )
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Figma "Valyutani tanlang / Ilova tilini tanlang / Ekran rejimi" select sheet
// (7073:13603). Distinct from the legacy `showDsActionDrawer` list: an X-close
// header, one white rounded card per option (selected card gets a blue border
// and a filled radio), and a pinned full-width "Saqlash" button that confirms.
// ---------------------------------------------------------------------------
class DsSelectItem<T> {
  const DsSelectItem({required this.value, required this.label, this.icon});
  final T value;
  final String label;
  // Optional leading glyph (Figma theme sheet rows: sun / moon / sun-moon).
  final IconData? icon;
}

const _kSelectSheetBg = Color(0xFFF6F7F9);
const _kSelectBlue = Color(0xFF004EEB);
const _kSelectLabel = Color(0xFF131313);
const _kSelectTitle = Color(0xFF101828);

/// Returns the chosen value when the user taps "Saqlash", or `null` if the
/// sheet is dismissed (X / scrim / back).
Future<T?> showDsSelectSheet<T>({
  required BuildContext context,
  required String title,
  required List<DsSelectItem<T>> items,
  T? currentValue,
  String? saveLabel,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _kSelectSheetBg,
    barrierColor: Colors.black.withValues(alpha: 0.40),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    useRootNavigator: true,
    builder: (ctx) => _DsSelectSheet<T>(
      title: title,
      items: items,
      currentValue: currentValue,
      saveLabel: saveLabel,
    ),
  );
}

class _DsSelectSheet<T> extends ConsumerStatefulWidget {
  const _DsSelectSheet({
    required this.title,
    required this.items,
    required this.currentValue,
    required this.saveLabel,
  });

  final String title;
  final List<DsSelectItem<T>> items;
  final T? currentValue;
  final String? saveLabel;

  @override
  ConsumerState<_DsSelectSheet<T>> createState() => _DsSelectSheetState<T>();
}

class _DsSelectSheetState<T> extends ConsumerState<_DsSelectSheet<T>> {
  late T? _selected = widget.currentValue;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.9;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header — X close (left) + title.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.pop(context),
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: Icon(LucideIcons.x, size: 24, color: Color(0xFF000000)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 24 / 16,
                        fontWeight: FontWeight.w600,
                        color: _kSelectTitle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final item = widget.items[i];
                  return _SelectCard(
                    label: item.label,
                    icon: item.icon,
                    active: item.value == _selected,
                    onTap: () => setState(() => _selected = item.value),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SelectSaveButton(
                label: widget.saveLabel ?? 'common.save'.tr(ref),
                onTap: () => Navigator.pop(context, _selected),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SelectCard extends StatelessWidget {
  const _SelectCard({
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          // Transparent border when inactive keeps the box size stable.
          border: Border.all(color: active ? _kSelectBlue : Colors.transparent, width: 1),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: _kSelectBlue),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  height: 18 / 14,
                  fontWeight: FontWeight.w500,
                  color: _kSelectLabel,
                ),
              ),
            ),
            _SelectRadio(active: active),
          ],
        ),
      ),
    );
  }
}

class _SelectRadio extends StatelessWidget {
  const _SelectRadio({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? const Color(0xFFEBF1FF) : const Color(0xFFF9FAFB),
        border: Border.all(color: active ? _kSelectBlue : const Color(0xFF98A2B3), width: 1),
      ),
      child: active
          ? const Center(
              child: SizedBox(
                width: 8,
                height: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(shape: BoxShape.circle, color: _kSelectBlue),
                ),
              ),
            )
          : null,
    );
  }
}

class _SelectSaveButton extends StatelessWidget {
  const _SelectSaveButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _kSelectBlue,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x0D101828), offset: Offset(0, 1), blurRadius: 2),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: 48,
            alignment: Alignment.center,
            child: Text(
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
    );
  }
}

// ---------------------------------------------------------------------------
// Figma "Kim joylagan" multi-select sheet (6745:18706). Same shell as
// `showDsSelectSheet` (X-close header, white rounded cards, pinned bottom
// button) but the cards carry a SQUARE checkbox and selection is multi:
// tapping toggles, the chosen cards get a blue border + filled checkbox, and
// "Tayyor" returns the full selected list. Dismissing (X / scrim) returns null.
// ---------------------------------------------------------------------------
const _kCheckBoxOn = Color(0xFFEAF1FF); // checked fill
const _kCheckBoxOff = Color(0xFFF9F9FA); // unchecked fill
const _kCheckBorderOff = Color(0xFF98A1B2); // unchecked border
const _kCheckLabel = Color(0xFF131313);

Future<List<T>?> showDsCheckSheet<T>({
  required BuildContext context,
  required String title,
  required List<DsSelectItem<T>> items,
  List<T> initialSelected = const [],
  String? saveLabel,
}) {
  return showModalBottomSheet<List<T>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _kSelectSheetBg,
    barrierColor: Colors.black.withValues(alpha: 0.40),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    useRootNavigator: true,
    builder: (ctx) => _DsCheckSheet<T>(
      title: title,
      items: items,
      initialSelected: initialSelected,
      saveLabel: saveLabel,
    ),
  );
}

class _DsCheckSheet<T> extends ConsumerStatefulWidget {
  const _DsCheckSheet({
    required this.title,
    required this.items,
    required this.initialSelected,
    required this.saveLabel,
  });

  final String title;
  final List<DsSelectItem<T>> items;
  final List<T> initialSelected;
  final String? saveLabel;

  @override
  ConsumerState<_DsCheckSheet<T>> createState() => _DsCheckSheetState<T>();
}

class _DsCheckSheetState<T> extends ConsumerState<_DsCheckSheet<T>> {
  late final Set<T> _selected = {...widget.initialSelected};

  void _toggle(T v) => setState(
        () => _selected.contains(v) ? _selected.remove(v) : _selected.add(v),
      );

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.9;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header — X close (left) + title.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.pop(context),
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: Icon(LucideIcons.x, size: 24, color: Color(0xFF000000)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 24 / 16,
                        fontWeight: FontWeight.w600,
                        color: _kSelectTitle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final item = widget.items[i];
                  return _CheckCard(
                    label: item.label,
                    active: _selected.contains(item.value),
                    onTap: () => _toggle(item.value),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SelectSaveButton(
                label: widget.saveLabel ?? 'common.done'.tr(ref),
                onTap: () => Navigator.pop(context, _selected.toList()),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _CheckCard extends StatelessWidget {
  const _CheckCard({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? _kSelectBlue : Colors.transparent, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  height: 18 / 14,
                  fontWeight: FontWeight.w500,
                  color: _kCheckLabel,
                ),
              ),
            ),
            _CheckBox(active: active),
          ],
        ),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: active ? _kCheckBoxOn : _kCheckBoxOff,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: active ? _kSelectBlue : _kCheckBorderOff, width: 1),
      ),
      child: active
          ? const Icon(LucideIcons.check, size: 14, color: _kSelectBlue)
          : null,
    );
  }
}
