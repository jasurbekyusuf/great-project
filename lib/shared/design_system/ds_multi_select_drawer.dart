import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Multi-select bottom sheet — Figma "Kim joylagan" picker (node 6745:18445).
///
/// White option cards (343×48, r12, 8px gap) on a #F3F4F7 sheet; the selected
/// card gets a blue border and its checkbox fills (#EBF1FF / #004EEB + check).
/// Confirmed with a full-width "Tayyor" button. Returns the chosen values, or
/// null if dismissed without confirming.
class DsMultiSelectItem<T> {
  const DsMultiSelectItem({required this.value, required this.label});
  final T value;
  final String label;
}

Future<List<T>?> showDsMultiSelectDrawer<T>({
  required BuildContext context,
  required String title,
  required List<DsMultiSelectItem<T>> items,
  required List<T> initialSelected,
  String confirmLabel = 'Tayyor',
}) {
  return showModalBottomSheet<List<T>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: FigmaPalette.sheetBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => _DsMultiSelectDrawer<T>(
      title: title,
      items: items,
      initialSelected: initialSelected,
      confirmLabel: confirmLabel,
    ),
  );
}

class _DsMultiSelectDrawer<T> extends StatefulWidget {
  const _DsMultiSelectDrawer({
    required this.title,
    required this.items,
    required this.initialSelected,
    required this.confirmLabel,
  });

  final String title;
  final List<DsMultiSelectItem<T>> items;
  final List<T> initialSelected;
  final String confirmLabel;

  @override
  State<_DsMultiSelectDrawer<T>> createState() => _DsMultiSelectDrawerState<T>();
}

class _DsMultiSelectDrawerState<T> extends State<_DsMultiSelectDrawer<T>> {
  late final Set<T> _selected = {...widget.initialSelected};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD0D5DD),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 16,
                  height: 24 / 16,
                  fontWeight: FontWeight.w600,
                  color: FigmaPalette.ink,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: widget.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final item = widget.items[i];
                  final on = _selected.contains(item.value);
                  return _OptionCard(
                    label: item.label,
                    selected: on,
                    onTap: () => setState(() {
                      if (on) {
                        _selected.remove(item.value);
                      } else {
                        _selected.add(item.value);
                      }
                    }),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _ConfirmButton(
              label: widget.confirmLabel,
              onTap: () => Navigator.pop(context, _selected.toList()),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? FigmaPalette.primary : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 18 / 14,
                    fontWeight: FontWeight.w500,
                    color: FigmaPalette.inkStrong,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _CheckBox(on: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: on ? const Color(0xFFEBF1FF) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: on ? FigmaPalette.primary : const Color(0xFF98A2B3),
        ),
      ),
      child: on
          ? const Icon(LucideIcons.check, size: 14, color: FigmaPalette.primary)
          : null,
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FigmaPalette.primary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 48,
          child: Center(
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
