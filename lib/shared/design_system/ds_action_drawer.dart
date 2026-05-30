import 'package:flutter/material.dart';
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

class _DsActionDrawer<T> extends StatefulWidget {
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
  State<_DsActionDrawer<T>> createState() => _DsActionDrawerState<T>();
}

class _DsActionDrawerState<T> extends State<_DsActionDrawer<T>> {
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
                      child: const Text('Bekor qilish'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _selected == null ? null : () => Navigator.pop(context, _selected),
                      child: const Text('Tasdiqlash'),
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
